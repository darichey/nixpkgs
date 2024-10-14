{
  lib,
  stdenv,
  fetchFromGitHub,
  makeWrapper,
  fetchYarnDeps,
  yarnConfigHook,
  yarnBuildHook,
  nodejs,
  git,
  zip,
  castlabs-electron
}:

stdenv.mkDerivation (finalAttrs: {
  pname = "kenku-fm";
  version = "1.4.3";

  src = fetchFromGitHub {
    # owner = "owlbear-rodeo";
    # repo = "kenku-fm";
    # rev = "refs/tags/v${finalAttrs.version}";
    # hash = "sha256-NoFQxjI35N2ddK+mDsdSSxAKNcdQuYnjj4mkx/3xTL8=";
    owner = "darichey";
    repo = "kenku-fm";
    rev = "4971f7302804130afd39c3e1f3565996913be842";
    hash = "sha256-rUZOLN6SYwczmoXmharnb1oddbD2EOuPqNSf/QWsYSs=";
  };

  yarnOfflineCache = fetchYarnDeps {
    yarnLock = "${finalAttrs.src}/yarn.lock";
    hash = "sha256-38onwOVxpFPNNxcCzXfw3PIQxmY1aoeseHraSJXsWNI=";
  };

  nativeBuildInputs = [
    yarnConfigHook
    yarnBuildHook
    makeWrapper
  ];

  buildInputs = [
    nodejs
    git
    zip
  ];

  yarnBuildScript = "package";

  env = {
    ELECTRON_SKIP_BINARY_DOWNLOAD = 1;
  };

  preBuild = ''
    mkdir electron-dist
    cp ${castlabs-electron.src} electron-dist/electron-v${castlabs-electron.version}-linux-x64.zip

    substituteInPlace forge.config.js \
      --replace-fail 'appBundleId: "com.kenku.fm",' 'appBundleId: "com.kenku.fm",
        electronZipDir:"electron-dist"'
  '';

  installPhase = ''
    runHook preInstall

    # cp -R out/Kenku\ FM-linux-x64 $out

    mkdir -p $out/share/lib/kenku-fm
    cp -r out/*/{locales,resources{,.pak}} $out/share/lib/kenku-fm

    makeWrapper ${lib.getExe castlabs-electron} $out/bin/kenku-fm \
        --add-flags $out/share/lib/kenku-fm/resources/app \
        --add-flags "\''${NIXOS_OZONE_WL:+\''${WAYLAND_DISPLAY:+--ozone-platform-hint=auto --enable-features=WaylandWindowDecorations}}" \
        --inherit-argv0

    runHook postInstall
  '';
})
