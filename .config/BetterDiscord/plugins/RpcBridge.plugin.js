/**
 * @name RpcBridge
 * @version 1.2.0
 * @description Exports what Discord actually shows (Rich Presence) plus unread inbox to
 *   ~/.cache/discord-rpc.json / ~/.cache/discord-inbox.json, and polls
 *   ~/.cache/discord-reply.json for reply / jump commands from the shell.
 * @author rice
 */
module.exports = class RpcBridge {
  start() {
    const fs = require("fs");
    const path = require("path");
    const HOME = process.env.HOME;
    if (!HOME) return;   // never guess a user path

    this.rpcFile = path.join(HOME, ".cache", "discord-rpc.json");
    this.inboxFile = path.join(HOME, ".cache", "discord-inbox.json");
    this.cmdFile = path.join(HOME, ".cache", "discord-cmd.json");

    this.lastRpc = "";
    this.lastInbox = "";
    this.preview = {};        // channelId -> {id, author, content, ts}
    this.previewTried = {};   // channelId -> lastMessageId we already fetched
    this.busy = false;

    const S = (name) => {
      try { return BdApi.Webpack.getStore(name); } catch (e) { return null; }
    };

    this.api = () => ({
      user: S("UserStore"),
      presence: S("PresenceStore"),
      local: S("LocalActivityStore"),
      read: S("ReadStateStore"),
      channels: S("ChannelStore"),
      guilds: S("GuildStore"),
      guildSettings: S("UserGuildSettingsStore"),
      messages: S("MessageStore"),
      actions: BdApi.Webpack.getByKeys("jumpToMessage", "_sendMessage"),
    });

    // ---------------------------------------------------------- presence
    this.writePresence = (fs) => {
      const { user, presence, local } = this.api();
      const me = user && user.getCurrentUser ? user.getCurrentUser() : null;
      let acts = [];
      try {
        if (presence && presence.getActivities && me) acts = presence.getActivities(me.id) || [];
      } catch (e) { acts = []; }
      // only what Discord is broadcasting; LocalActivityStore holds raw RPC
      // requests that may never be shown (hidden game activity, stale clients)
      const list = acts.filter((a) => a && a.type !== 4);
      const act = list.find((a) => a.type === 1) || list[0];
      if (!act) {
        if (this.lastRpc) fs.rmSync(this.rpcFile, { force: true });
        this.lastRpc = "";
        return;
      }
      const rpc = JSON.stringify({
        ts: Date.now(),
        type: act.type,
        name: act.name || "",
        details: act.details || "",
        state: act.state || "",
        start: act.timestamps && act.timestamps.start ? +act.timestamps.start : 0,
      });
      fs.writeFileSync(this.rpcFile, rpc);
      this.lastRpc = rpc;
    };

    // ---------------------------------------------------------- inbox
    // DMs first (they are what you actually reply to), then unread channels
    // from servers you have NOT muted. Muted servers never show up.
    this.writeInbox = (fs) => {
      const { read, channels, guilds, guildSettings, messages, actions, user } = this.api();
      if (!read || !channels) return;

      let states = [];
      try {
        states = read.getAllReadStates ? read.getAllReadStates() : [];
        if (!Array.isArray(states)) states = Object.values(states || {});
      } catch (e) { states = []; }
      const stateOf = {};
      for (const rs of states) if (rs && rs.channelId) stateOf[rs.channelId] = rs;

      const rows = [];
      const seen = {};
      let fetches = 0;
      const budget = 3;

      const who = (r) => {
        if (!r) return "";
        if (typeof r === "string") {
          const u = user && user.getUser ? user.getUser(r) : null;
          return (u && (u.globalName || u.username)) || "";
        }
        return r.globalName || r.username || "";
      };
      const preview = (cid, lastId) => {
        if (this.preview[cid] && (!lastId || this.preview[cid].id === lastId)) return this.preview[cid];
        const l = messages && messages.getLastMessage ? messages.getLastMessage(cid) : null;
        if (l) {
          this.preview[cid] = {
            id: l.id,
            author: (l.author && (l.author.globalName || l.author.username)) || "",
            content: String(l.content || ""),
            ts: l.timestamp ? new Date(l.timestamp).getTime() : 0,
          };
          return this.preview[cid];
        }
        // one fetch per channel per new message, few per scan
        if (actions && actions.fetchMessages && lastId && this.previewTried[cid] !== lastId && fetches < budget) {
          fetches++;
          this.previewTried[cid] = lastId;
          Promise.resolve(actions.fetchMessages({ channelId: cid, limit: 1 })).then((res) => {
            const m = Array.isArray(res) ? res[0] : (res && res.messages ? res.messages[0] : null);
            if (!m) return;
            this.preview[cid] = {
              id: m.id,
              author: (m.author && (m.author.globalName || m.author.username)) || "",
              content: String(m.content || ""),
              ts: m.timestamp ? new Date(m.timestamp).getTime() : 0,
            };
          }).catch(() => {});
        }
        return null;
      };

      // ---- DMs and group DMs
      try {
        const dms = (channels.getSortedPrivateChannels ? channels.getSortedPrivateChannels() : []).slice(0, 12);
        for (const ch of dms) {
          if (!ch || seen[ch.id]) continue;
          seen[ch.id] = true;
          const rs = stateOf[ch.id];
          const unread = read.getUnreadCount ? read.getUnreadCount(ch.id) : 0;
          const mentions = read.getMentionCount ? read.getMentionCount(ch.id) : 0;
          const lastId = (rs && rs._lastMessageId) || "";
          const p = preview(ch.id, lastId);
          const name = (ch.recipients || []).map(who).filter(Boolean).join(", ");
          if (!p && !unread && !mentions) continue;   // nothing to say about it yet
          rows.push({
            id: ch.id,
            name: name || ch.name || "Direct message",
            guild: "",
            author: (p && p.author) || "",
            content: (p && p.content) || "",
            ts: (p && p.ts) || 0,
            unread: unread,
            mentions: mentions,
            dm: true,
            lastId: lastId || (p && p.id) || "",
          });
        }
      } catch (e) {}

      // ---- unread channels in servers you have not muted
      for (const rs of states) {
        try {
          const cid = rs.channelId;
          if (seen[cid]) continue;
          const unread = read.getUnreadCount ? read.getUnreadCount(cid) : 0;
          const mentions = read.getMentionCount ? read.getMentionCount(cid) : 0;
          if (!unread && !mentions) continue;
          const ch = channels.getChannel ? channels.getChannel(cid) : null;
          if (!ch || ![0, 5].includes(ch.type)) continue;
          seen[cid] = true;
          if (guildSettings) {
            if (guildSettings.isMuted && ch.guild_id && guildSettings.isMuted(ch.guild_id)) continue;
            if (guildSettings.isChannelMuted && guildSettings.isChannelMuted(cid)) continue;
          }
          const lastId = rs._lastMessageId || "";
          const p = preview(cid, lastId);
          const g = ch.guild_id && guilds && guilds.getGuild ? guilds.getGuild(ch.guild_id) : null;
          rows.push({
            id: cid,
            name: ch.name || "channel",
            guild: (g && g.name) || "",
            author: (p && p.author) || "",
            content: (p && p.content) || "",
            ts: (p && p.ts) || 0,
            unread: unread,
            mentions: mentions,
            dm: false,
            lastId: lastId || (p && p.id) || "",
          });
        } catch (e) {}
      }

      // pinned: unread/mentions first, DMs next, then newest
      // DMs first (they are what you reply to), then unread servers by time
      rows.sort((a, b) => (b.mentions - a.mentions)
        || ((b.dm ? 1 : 0) - (a.dm ? 1 : 0))
        || (((b.unread > 0) ? 1 : 0) - ((a.unread > 0) ? 1 : 0))
        || (b.ts - a.ts));
      const out = JSON.stringify({ ts: Date.now(), channels: rows.slice(0, 8) });
      fs.writeFileSync(this.inboxFile, out);
      this.lastInbox = out;
    };

    // ---------------------------------------------------------- commands
    this.pump = (fs) => {
      let cmd = null;
      try { cmd = JSON.parse(fs.readFileSync(this.cmdFile, "utf8")); } catch (e) { return; }
      const { actions } = this.api();
      try {
        if (cmd && cmd.action === "jump" && cmd.channelId) {
          // jumpToMessage both selects the channel and lands on the message;
          // selectChannel alone does not always switch the visible channel
          if (cmd.messageId && actions && actions.jumpToMessage)
            actions.jumpToMessage({ channelId: cmd.channelId, messageId: cmd.messageId });
          else {
            const ch = BdApi.Webpack.getByKeys("selectChannel");
            if (ch && ch.selectChannel) ch.selectChannel({ guild_id: cmd.guildId || null, channel_id: cmd.channelId });
            else BdApi.Logger.warn("RpcBridge", "selectChannel not found");
          }
        } else if (cmd && cmd.channelId && cmd.content && actions && actions.sendMessage) {
          actions.sendMessage(cmd.channelId, { content: String(cmd.content) });
          BdApi.Logger.info("RpcBridge", "replied in " + cmd.channelId);
        }
      } catch (e) {
        BdApi.Logger.error("RpcBridge", "command failed", e);
      }
      try { fs.rmSync(this.cmdFile, { force: true }); } catch (e) {}
    };

    this.scan = () => {
      if (this.busy) return;
      this.busy = true;
      try {
        const fs = require("fs");
        this.writePresence(fs);
        this.writeInbox(fs);
        this.pump(fs);
      } catch (e) {
        BdApi.Logger.error("RpcBridge", "scan failed", e);
      } finally {
        this.busy = false;
      }
    };

    this.scan();
    this.iv = setInterval(this.scan, 2000);
  }

  stop() {
    clearInterval(this.iv);
    const fs = require("fs");
    for (const f of [this.rpcFile, this.inboxFile, this.cmdFile]) {
      try { fs.rmSync(f, { force: true }); } catch (e) {}
    }
  }
};
