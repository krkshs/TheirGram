namespace MyTelegram.Messenger.Handlers.LatestLayer.Chatlists;
/// <summary>
/// Export a <a href="https://corefork.telegram.org/api/folders">folder »</a>, creating a <a href="https://corefork.telegram.org/api/links#chat-folder-links">chat folder deep link »</a>.
/// Possible errors
/// Code Type Description
/// 400 CHANNEL_INVALID The provided channel is invalid.
/// 400 CHANNEL_PRIVATE You haven't joined this channel/supergroup.
/// 400 CHATLISTS_TOO_MUCH You have created too many folder links, hitting the <code>chatlist_invites_limit_default</code>/<code>chatlist_invites_limit_premium</code> <a href="https://corefork.telegram.org/api/config#chatlist-invites-limit-default">limits »</a>.
/// 400 CHAT_ADMIN_REQUIRED You must be an admin in this chat to do this.
/// 400 FILTER_ID_INVALID The specified filter ID is invalid.
/// 400 FILTER_NOT_SUPPORTED The specified filter cannot be used in this context.
/// 400 INVITES_TOO_MUCH The maximum number of per-folder invites specified by the <code>chatlist_invites_limit_default</code>/<code>chatlist_invites_limit_premium</code> <a href="https://corefork.telegram.org/api/config#chatlist-invites-limit-default">client configuration parameters »</a> was reached.
/// 400 PEERS_LIST_EMPTY The specified list of peers is empty.
/// <para><c>See <a href="https://corefork.telegram.org/method/chatlists.exportChatlistInvite"/> </c></para>
/// </summary>
/// <remarks>
/// Access: [User ✔] [Bot ✖] [Anonymous ✖]
/// </remarks>
internal sealed class ExportChatlistInviteHandler : RpcResultObjectHandler<MyTelegram.Schema.Chatlists.RequestExportChatlistInvite, MyTelegram.Schema.Chatlists.IExportedChatlistInvite>
{
    protected override Task<MyTelegram.Schema.Chatlists.IExportedChatlistInvite> HandleCoreAsync(IRequestInput input, MyTelegram.Schema.Chatlists.RequestExportChatlistInvite obj)
    {
        var filter = new MyTelegram.Schema.TDialogFilter
        {
            Id = 1,
            Title = new MyTelegram.Schema.TTextWithEntities { Text = obj.Title ?? "TheirGram", Entities = new MyTelegram.Schema.TVector<MyTelegram.Schema.IMessageEntity>() },
            PinnedPeers = new MyTelegram.Schema.TVector<MyTelegram.Schema.IInputPeer>(),
            IncludePeers = new MyTelegram.Schema.TVector<MyTelegram.Schema.IInputPeer>(),
            ExcludePeers = new MyTelegram.Schema.TVector<MyTelegram.Schema.IInputPeer>()
        };
        var invite = new MyTelegram.Schema.TExportedChatlistInvite
        {
            Title = obj.Title ?? "TheirGram",
            Url = "https://t.me/addlist/theregram_" + Guid.NewGuid().ToString("N").Substring(0, 8),
            Peers = new MyTelegram.Schema.TVector<MyTelegram.Schema.IPeer>()
        };
        var result = new MyTelegram.Schema.Chatlists.TExportedChatlistInvite
        {
            Filter = filter,
            Invite = invite
        };
        return Task.FromResult<MyTelegram.Schema.Chatlists.IExportedChatlistInvite>(result);
    }
}