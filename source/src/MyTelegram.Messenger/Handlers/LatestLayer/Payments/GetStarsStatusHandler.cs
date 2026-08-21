using MongoDB.Driver;
using MyTelegram.Converters.TLObjects.Payments;

namespace MyTelegram.Messenger.Handlers.LatestLayer.Payments;
/// <summary>
/// Get the current <a href="https://corefork.telegram.org/api/stars">Telegram Stars balance</a> of the current account (with peer=<a href="https://corefork.telegram.org/constructor/inputPeerSelf">inputPeerSelf</a>), or the stars balance of the bot specified in <code>peer</code>.
/// Possible errors
/// Code Type Description
/// 403 BOT_ACCESS_FORBIDDEN The specified method <em>can</em> be used over a <a href="https://corefork.telegram.org/api/bots/connected-business-bots">business connection</a> for some operations, but the specified query attempted an operation that is not allowed over a business connection.
/// 400 BUSINESS_CONNECTION_INVALID The <code>connection_id</code> passed to the wrapping <a href="https://corefork.telegram.org/api/business">invokeWithBusinessConnection</a> call is invalid.
/// 400 PEER_ID_INVALID The provided peer id is invalid.
/// <para><c>See <a href="https://corefork.telegram.org/method/payments.getStarsStatus"/> </c></para>
/// </summary>
/// <remarks>
/// Access: [User ✔] [Bot ✖] [Anonymous ✖]
/// </remarks>
internal sealed class GetStarsStatusHandler(
    ILayeredService<IStarsStatusConverter> starsStatusLayeredService,
    IMongoClient mongoClient,
    IPeerHelper peerHelper) : RpcResultObjectHandler<MyTelegram.Schema.Payments.RequestGetStarsStatus, MyTelegram.Schema.Payments.IStarsStatus>
{
    protected override async Task<MyTelegram.Schema.Payments.IStarsStatus> HandleCoreAsync(IRequestInput input, MyTelegram.Schema.Payments.RequestGetStarsStatus obj)
    {
        try
        {
            var db = mongoClient.GetDatabase("tg");
            var col = db.GetCollection<StarsBalanceDoc>("StarsBalance");
            long targetId = input.UserId;
            if (obj.Peer != null)
            {
                try
                {
                    var peer = peerHelper.GetPeer(obj.Peer, input.UserId);
                    if (peer.PeerType == PeerType.User) targetId = peer.PeerId;
                }
                catch { }
            }
            var doc = await col.Find(Builders<StarsBalanceDoc>.Filter.Eq(x => x.UserId, targetId)).FirstOrDefaultAsync();
            if (doc != null)
            {
                if (obj.Ton)
                    return new MyTelegram.Schema.Payments.TStarsStatus
                    {
                        Balance = new MyTelegram.Schema.TStarsTonAmount { Amount = doc.Amount },
                        Chats = [], Users = [], History = []
                    };
                return new MyTelegram.Schema.Payments.TStarsStatus
                {
                    Balance = new MyTelegram.Schema.TStarsAmount { Amount = doc.Amount },
                    Chats = [], Users = [], History = []
                };
            }
        }
        catch { }
        return starsStatusLayeredService.GetConverter(input.Layer).ToStarsStatus(obj.Ton);
    }

    private sealed class StarsBalanceDoc
    {
        public long UserId { get; set; }
        public long Amount { get; set; }
    }
}