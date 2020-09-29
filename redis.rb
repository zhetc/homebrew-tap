class Redis < Formula
  desc "Persistent key-value database, with built-in net interface"
  homepage "https://redis.io/"
  url "http://127.0.0.1/static/redis-6.0.6.tar.gz"
  sha256 "12ad49b163af5ef39466e8d2f7d212a58172116e5b441eebecb4e6ca22363d94"
  license "BSD-3-Clause"
  head "https://github.com/redis/redis.git", branch: "unstable"

#   livecheck do
#     url "http://download.redis.io/releases/"
#     regex(/href=.*?redis[._-]v?(\d+(?:\.\d+)+)\.t/i)
#   end

#   bottle do
#     cellar :any
#     sha256 "d015cdb6b89904d6f81ffec5227363504a956d1ebb7c04e2993733a2677360ad" => :catalina
#     sha256 "dbaa57e090b18de53777434f31270666e1e8ba9c1a7ef97ef19d2e49456cb3c9" => :mojave
#     sha256 "458627bc0cd6dfa2d0c430cac842234ea3beb10725f2b0cc7ca246ec4ffe0017" => :high_sierra
#   end

  depends_on "openssl@1.1"

  def install
    system "make", "install", "PREFIX=#{prefix}", "CC=#{ENV.cc}", "BUILD_TLS=yes"

    %w[redis/run/ redis/data/ redis/log/].each { |p| (var/p).mkpath }
    (etc/"redis/").mkpath

    # Fix up default conf file to match our paths
    inreplace "redis.conf" do |s|
      s.gsub! "/var/run/redis.pid", "#{var}/redis/run/redis.pid"
      s.gsub! "dir ./", "dir #{var}/redis/data/"
      s.sub!  /^bind .*$/, "bind 127.0.0.1 ::1"
    end

    (etc/"redis/").install "redis.conf"
    (etc/"redis/").install "sentinel.conf" => "redis-sentinel.conf"
  end

  plist_options manual: "redis-server #{HOMEBREW_PREFIX}/etc/redis/redis.conf"

  def plist
    <<~EOS
      <?xml version="1.0" encoding="UTF-8"?>
      <!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
      <plist version="1.0">
        <dict>
          <key>KeepAlive</key>
          <dict>
            <key>SuccessfulExit</key>
            <false/>
          </dict>
          <key>Label</key>
          <string>#{plist_name}</string>
          <key>ProgramArguments</key>
          <array>
            <string>#{opt_bin}/redis-server</string>
            <string>#{etc}/redis/redis.conf</string>
            <string>--daemonize no</string>
          </array>
          <key>RunAtLoad</key>
          <true/>
          <key>WorkingDirectory</key>
          <string>#{var}/redis/</string>
          <key>StandardErrorPath</key>
          <string>#{var}/redis/log/redis.log</string>
          <key>StandardOutPath</key>
          <string>#{var}/redis/log/redis.log</string>
        </dict>
      </plist>
    EOS
  end

  test do
    system bin/"redis-server", "--test-memory", "2"
    %w[redis/run/ redis/data/ redis/log/].each { |p| assert_predicate var/p, :exist?, "#{var/p} doesn't exist!" }
  end
end
