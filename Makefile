include Makefile.config

all: test

deps:
	flatpak --user remote-add --if-not-exists endless-electron-apps --from https://s3-us-west-2.amazonaws.com/electron-flatpak.endlessm.com/endless-electron-apps.flatpakrepo
	flatpak --user remote-add --if-not-exists gnome --from https://sdk.gnome.org/gnome.flatpakrepo
	flatpak --user install endless-electron-apps io.atom.electron.BaseApp || true
	flatpak --user install gnome org.freedesktop.Platform//1.6 org.freedesktop.Sdk//1.6 || true

test: deps repo com.discordapp.Client.json
	flatpak-builder --force-clean --repo=repo --ccache --require-changes discord com.discordapp.Client.json
	flatpak build-update-repo repo

release: deps release-repo com.discordapp.Client.json
	if [ "x${RELEASE_GPG_KEY}" == "x" ]; then echo Must set RELEASE_GPG_KEY in Makefile.config, try \'make gpg-key\'; exit 1; fi
	flatpak-builder --force-clean --repo=release-repo  --ccache --gpg-homedir=gpg --gpg-sign=${RELEASE_GPG_KEY} discord  com.discordapp.Client.json
	flatpak build-update-repo --generate-static-deltas --gpg-homedir=gpg --gpg-sign=${RELEASE_GPG_KEY} release-repo

repo:
	ostree init --mode=archive-z2 --repo=repo

release-repo:
	ostree init --mode=archive-z2 --repo=release-repo

gpg-key:
	if [ "x${KEY_USER}" == "x" ]; then echo Must set KEY_USER in Makefile.config; exit 1; fi
	mkdir -p gpg
	gpg2 --homedir gpg --quick-gen-key ${KEY_USER}
	echo Enter the above gpg key id as RELEASE_GPG_KEY in Makefile.config

discord.flatpakref: discord.flatpakref.in
	sed -e 's|@URL@|${URL}|g' -e 's|@GPG@|$(shell gpg2 --homedir=gpg --export ${RELEASE_GPG_KEY} | base64 | tr -d '\n')|' $< > $@

.PHONY: deps test release gpg-key
