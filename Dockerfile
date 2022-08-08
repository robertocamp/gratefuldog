FROM golang:1.18-alpine as dev

WORKDIR /cmd 


FROM golang:1.18-alpine as build
WORKDIR /gratefuldog
COPY ./cmd/* /gratefuldog/
RUN cd /gratefuldog && go mod download


RUN go mod tidy
RUN CGO_ENABLED=0 GOOS=linux GOARCH=amd64 go build -a -installsuffix cgo -o cmd .

###########START NEW IMAGE###################
FROM alpine:latest
RUN apk update && apk add --no-cache git ca-certificates && update-ca-certificates
COPY --from=build /gratefuldog/cmd ./
# COPY --from=builder . .
CMD ["./cmd"]

