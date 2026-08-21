# TheirGram

[![API Layer](https://img.shields.io/badge/API_Layer-224-greengreen)](https://corefork.telegram.org/methods)
[![MTProto](https://img.shields.io/badge/MTProto_Protocol-2.0-green)](https://corefork.telegram.org/mtproto/)
[![Direct](https://img.shields.io/badge/Direct-@vaggin-0088cc)](https://telegram.me/vaggin)

TheirGram is a self-hosted C# implementation of the Telegram server-side API, designed for private deployments and extensibility. Fork of MyTelegram — layer 224 · `192.168.0.200:20443` · `gram.there.durov` · fingerprint `0xce27f5081215bda4`.

## Supported Features

### Current Features
- [![API Layer](https://img.shields.io/badge/API_Layer-224-greengreen)](https://corefork.telegram.org/methods)
- MTProto Transports: `Abridged`, `Intermediate`
- Private Chat
- Supergroup Chat
- Channel
- Chatlist (Dialog Filters & Chat Folder Deep Links)
- Direct Messages (MonoForum)

### Upcoming Features
- End-to-End Encrypted Chat
- Voice & Video Calls
- Bot Support
- Privacy Settings & 2FA
- Stickers
- Reactions
- Star Gifts
- Forum Topics
- Themes & Wallpapers
- Auto-Delete Messages
- Scheduled Messages
- Telegram Business
- Stories
- Passkey Login
- Email Login
- Email Sender
- Push Server (Firebase)

---

## Running TheirGram Server

### Run with Docker

1. Download the Docker Compose configuration files:

https://raw.githubusercontent.com/loyldg/mytelegram/dev/docker/compose/docker-compose.yml  
https://raw.githubusercontent.com/loyldg/mytelegram/dev/docker/compose/.env

2. Edit `.env` and replace `192.168.1.100` with your own server IP address.

3. Start the server:

```
mkdir -p ./data/mytelegram
chmod -R a+w ./data/mytelegram
docker compose up
```
4. Default verification code (for testing only): `22222`
5. Default listening ports: `20443`, `20543`, `20643`, `20644`, `30443`, `30444`

## Building Docker Images

### Linux / amd64
`./build-all-amd64.sh`

### Linux / arm64
`./build-all-arm64.sh`

## TheirGram Clients

| Platform | Repository |
|----------|------------|
| Desktop (TDesktop) | https://github.com/loyldg/mytelegram-tdesktop |
| Android | https://github.com/loyldg/mytelegram-android |
| iOS | https://github.com/loyldg/mytelegram-iOS |
| WebK | https://github.com/loyldg/mytelegram-webk |
| WebA | https://github.com/loyldg/mytelegram-weba |

### Configure Clients
1. Clone the client source code.  
2. Search for `192.168.1.100` in all files and replace it with your own server IP (`192.168.0.200` for `gram.there.durov`).

---

## Support TheirGram

If you find TheirGram helpful, please consider giving the project a ⭐.


## Feedback

- Direct: https://telegram.me/vaggin
