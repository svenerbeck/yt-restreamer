FROM python:3.12-alpine

RUN apk add --no-cache ffmpeg curl bash jq && \
    pip install yt-dlp

WORKDIR /app

COPY multi-streamer.sh /app/multi-streamer.sh
COPY streams.json /app/streams.json

RUN chmod +x /app/multi-streamer.sh

CMD ["/app/multi-streamer.sh"]