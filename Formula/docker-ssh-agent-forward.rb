class DockerSshAgentForward < Formula
  desc "Forward SSH agent socket into a container"
  homepage "https://github.com/avsm/docker-ssh-agent-forward"
  head "https://github.com/avsm/docker-ssh-agent-forward.git"

  patch :DATA

  def install
    ENV['PATH']   = "#{ENV['PATH']}:/usr/local/bin"
    ENV['PREFIX'] = prefix

    system "make"
    system "make", "install"
  end

  def caveats; <<-EOS.undent
    Add the following line to your profile (e.g. ~/.bashrc, ~/.profile, ~/.bash_profile, or ~/.zshrc)

      [[ -f $(brew --prefix)/bin/pinata-ssh-env ]] && eval $($(brew --prefix)/bin/pinata-ssh-env 2>/dev/null)

    EOS
  end

  plist_options :manual => "pinata-ssh-forward"

  def plist; <<-EOS.undent
      <?xml version="1.0" encoding="UTF-8"?>
      <!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
      <plist version="1.0">
        <dict>
          <key>KeepAlive</key>
          <true/>
          <key>Label</key>
          <string>#{plist_name}</string>
          <key>ProgramArguments</key>
          <array>
            <string>#{HOMEBREW_PREFIX}/bin/pinata-ssh-forward</string>
            <string>--daemon</string>
          </array>
          <key>EnvironmentVariables</key>
          <dict>
          <key>PATH</key>
          <string>/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/bin</string>
          </dict>
          <key>RunAtLoad</key>
          <true/>
          <key>WorkingDirectory</key>
          <string>#{var}</string>
          <key>StandardErrorPath</key>
          <string>#{var}/log/docker-ssh-agent-forward.log</string>
          <key>StandardOutPath</key>
          <string>#{var}/log/docker-ssh-agent-forward.log</string>
        </dict>
      </plist>
    EOS
  end

end
__END__
diff --git a/Makefile b/Makefile
index 49c0488..3bdbc65 100644
--- a/Makefile
+++ b/Makefile
@@ -13,5 +13,6 @@ install:
 	cp ssh-find-agent.sh $(PREFIX)/share/pinata-ssh-agent/ssh-find-agent.sh
 	@mkdir -p $(BINDIR)
 	cp pinata-build-sshd.sh $(BINDIR)/pinata-build-sshd
+	cp pinata-ssh-env.sh $(BINDIR)/pinata-ssh-env
 	cp pinata-ssh-forward.sh $(BINDIR)/pinata-ssh-forward
 	cp pinata-ssh-mount.sh $(BINDIR)/pinata-ssh-mount
diff --git a/pinata-ssh-env.sh b/pinata-ssh-env.sh
new file mode 100755
index 0000000..1173e5b
--- /dev/null
+++ b/pinata-ssh-env.sh
@@ -0,0 +1,8 @@
+#!/bin/sh
+
+LOCAL_STATE=~/.pinata-sshd
+AGENT=`cat ${LOCAL_STATE}/agent_socket_path | sed -e 's,/tmp/,,g'`
+
+echo "Run this command to configure your shell:\neval \$(pinata-ssh-env)" >&2
+echo "export PINATA_LOCAL_AGENT=$LOCAL_STATE/$AGENT"
+echo "export PINATA_SSH_AUTH_SOCK=/tmp/ssh-agent.sock"
diff --git a/pinata-ssh-forward.sh b/pinata-ssh-forward.sh
index 4b236d4..d630c5e 100755
--- a/pinata-ssh-forward.sh
+++ b/pinata-ssh-forward.sh
@@ -27,3 +27,7 @@ echo 'can be added to "docker run" to mount the SSH agent socket.'
 echo ""
 echo 'For example:'
 echo 'docker run -it `pinata-ssh-mount` ocaml/opam ssh git@github.com'
+
+if [ "$1" == "--daemon" ]; then
+    tail -f /dev/null
+fi
diff --git a/pinata-ssh-mount.sh b/pinata-ssh-mount.sh
index 9835091..e540652 100755
--- a/pinata-ssh-mount.sh
+++ b/pinata-ssh-mount.sh
@@ -1,5 +1,4 @@
 #!/bin/sh
 
-LOCAL_STATE=~/.pinata-sshd
-AGENT=`cat ${LOCAL_STATE}/agent_socket_path | sed -e 's,/tmp/,,g'`
-echo "-v ${LOCAL_STATE}/$AGENT:/tmp/ssh-agent.sock --env SSH_AUTH_SOCK=/tmp/ssh-agent.sock"
+eval $(pinata-ssh-env 2>/dev/null)
+echo "-v $PINATA_LOCAL_AGENT:$PINATA_SSH_AUTH_SOCK --env SSH_AUTH_SOCK=$PINATA_SSH_AUTH_SOCK"
