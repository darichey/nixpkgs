{
  lib,
  stdenv,
  fetchurl,
  unzip,
  makeWrapper,
  wrapGAppsHook3,
  alsa-lib,
  at-spi2-atk,
  cairo,
  cups,
  dbus,
  expat,
  gdk-pixbuf,
  glib,
  gtk3,
  nss,
  nspr,
  xorg,
  pango,
  pciutils,
  systemd,
  libdrm,
  mesa,
  libxkbcommon,
  libxshmfence,
  libGL,
  vulkan-loader,

}:
stdenv.mkDerivation (finalAttrs: {
  pname = "castlabs-electron";
  version = "29.0.1+wvcus";

  src = fetchurl {
    url = "https://github.com/castlabs/electron-releases/releases/download/v29.0.1%2Bwvcus/electron-v29.0.1+wvcus-linux-x64.zip";
    hash = "sha256-ek9vKdgYcROTdu2lQr3re6qxBCKzfP4hOjqbPu21FY8=";
  };

  electronLibPath = lib.makeLibraryPath ([
    alsa-lib
    at-spi2-atk
    cairo
    cups
    dbus
    expat
    gdk-pixbuf
    glib
    gtk3
    nss
    nspr
    xorg.libX11
    xorg.libxcb
    xorg.libXcomposite
    xorg.libXdamage
    xorg.libXext
    xorg.libXfixes
    xorg.libXrandr
    xorg.libxkbfile
    pango
    pciutils
    stdenv.cc.cc.lib
    systemd
    libdrm
    mesa
    libxkbcommon
    libxshmfence
    libGL
    vulkan-loader
  ]);

  buildInputs = [
    glib
    gtk3
  ];

  nativeBuildInputs = [
    unzip
    makeWrapper
    wrapGAppsHook3
  ];

  dontUnpack = true;
  dontBuild = true;

  installPhase = ''
    mkdir -p $out/libexec/electron $out/bin
    unzip -d $out/libexec/electron $src
    ln -s $out/libexec/electron/electron $out/bin
    chmod u-x $out/libexec/electron/*.so*
  '';

  postFixup = ''
    patchelf \
      --set-interpreter "$(cat $NIX_CC/nix-support/dynamic-linker)" \
      --set-rpath "${finalAttrs.electronLibPath}:$out/libexec/electron" \
      $out/libexec/electron/.electron-wrapped \
      $out/libexec/electron/.chrome_crashpad_handler-wrapped

    # patch libANGLE
    patchelf \
      --set-rpath "${
        lib.makeLibraryPath [
          libGL
          pciutils
          vulkan-loader
        ]
      }" \
      $out/libexec/electron/lib*GL*

    # replace bundled vulkan-loader
    rm "$out/libexec/electron/libvulkan.so.1"
    ln -s -t "$out/libexec/electron" "${lib.getLib vulkan-loader}/lib/libvulkan.so.1"
  '';

  meta = with lib; {
    mainProgram = "electron";
  };
})
