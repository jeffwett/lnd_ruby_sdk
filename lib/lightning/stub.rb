# Namespace for classes and modules that handle communication with your LND node
module Lightning
  # When this module is included in another class, we have access to the
  # pre-generated stub (client) and can use it to communicate with the
  # gRPC api.
  # @since 0.1.0
  class << self
    private

    # On the client side, the client has a local object known as stub
    # (for other languages, the preferred term is client) that implements
    # the same methods as the service. The client can then just call those
    # methods on the local object, wrapping the parameters for the call in
    # the appropriate protocol buffer message type - gRPC looks after sending
    # the request(s) to the server and returning the server's protocol buffer
    # response(s). Read more about stubs at: http://tiny.cc/nwuc5y. We're using
    # a pre-generated stub created with inspiration from the tutorial at:
    # https://github.com/lightningnetwork/lnd/blob/master/docs/grpc/ruby.md
    # @since 0.1.0
    # @return [Lnrpc::Lightning::Stub]
    def stub
      config = Lightning.configuration

      Lnrpc::Lightning::Stub.new(
        "#{config.grcp_host}:#{config.grcp_port}",
        credentials,
        interceptors: [MacaroonInterceptor.new(macaroon)]
      )
    end

    # Macaroon files works like cookies and are used to authenticate with
    # LND gRPC. By default, when lnd starts, it creates three files which
    # contain macaroons: a file called admin.macaroon, which contains a
    # macaroon with no caveats, a file called readonly.macaroon, which is
    # the same macaroon but with an additional caveat, that permits only
    # methods that don't change the state of lnd, and invoice.macaroon,
    # which only has access to invoice related methods. You can learn more
    # about LND macaroons at: http://tiny.cc/1nuc5y
    # @since 0.1.0
    # @return [Binary]
    def macaroon
      config = Lightning.configuration

      macaroon_binary = File.read(
        File.expand_path(config.macaroon_path)
      )

      macaroon_binary.each_byte.map { |b| b.to_s(16).rjust(2, '0') }.join
    end

    # Get SSL credentials from the tls.cert file generated by
    # LND. This file is normally generated by LND and will be
    # created by default at ~/.lnd/tls.cert on the server running
    # your LND node. We will use it to establish a secured connection
    # between your app and the node/server.
    # @since 0.1.0
    # @return [GRPC::Core::ChannelCredentials]
    def credentials
      config = Lightning.configuration

      ENV['GRPC_SSL_CIPHER_SUITES'] =
        ENV['GRPC_SSL_CIPHER_SUITES'] || 'HIGH+ECDSA'

      certificate = File.read(File.expand_path(config.certificate_path))
      GRPC::Core::ChannelCredentials.new(certificate)
    end
  end
end
