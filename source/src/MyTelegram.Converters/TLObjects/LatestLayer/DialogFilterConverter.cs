namespace MyTelegram.Converters.TLObjects.LatestLayer;

internal sealed class DialogFilterConverter(IObjectMapper objectMapper) : IDialogFilterConverter, ITransientDependency
{
    public int Layer => Layers.LayerLatest;

    public IDialogFilter ToDialogFilter(DialogFilter dialogFilter)
    {
        if (dialogFilter.IsChatlist)
        {
            var chatlist = new TDialogFilterChatlist
            {
                Id = dialogFilter.Id,
                Title = dialogFilter.Title,
                TitleNoanimate = dialogFilter.TitleNoAnimate,
                Emoticon = dialogFilter.Emoticon,
                Color = dialogFilter.Color,
                HasMyInvites = false,
                PinnedPeers = new TVector<MyTelegram.Schema.IInputPeer>(),
                IncludePeers = new TVector<MyTelegram.Schema.IInputPeer>()
            };
            foreach (var peer in dialogFilter.PinnedPeers)
            {
                chatlist.PinnedPeers.Add(peer.ToInputPeer());
            }
            foreach (var peer in dialogFilter.IncludePeers)
            {
                chatlist.IncludePeers.Add(peer.ToInputPeer());
            }
            return chatlist;
        }
        return objectMapper.Map<DialogFilter, TDialogFilter>(dialogFilter);
    }
}