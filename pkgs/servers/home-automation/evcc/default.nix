{ lib
, buildGo120Module
, fetchFromGitHub
, fetchNpmDeps
, cacert
, go
, git
, enumer
, mockgen
, nodejs
, npmHooks
, nix-update-script
, nixosTests
, stdenv
}:

buildGo120Module rec {
  pname = "evcc";
  version = "0.114.0";

  src = fetchFromGitHub {
    owner = "evcc-io";
    repo = pname;
    rev = version;
    hash = "sha256-YPqt1UfXP2LGSopQuM4PXQJG3MmXg+5VjDpBKpV5axI=";
  };

  vendorHash = "sha256-CNBwOVykQW7RUuf6oFTxO2DU6sd5IJVqN+6FPytQh+U=";

  npmDeps = fetchNpmDeps {
    inherit src;
    hash = "sha256-LGlM+itulqtlwyVKfVGiZtTpcCmx+lVvE3JOFkYRHXk=";
  };

  nativeBuildInputs = [
    nodejs
    npmHooks.npmConfigHook
  ];

  overrideModAttrs = _: {
    nativeBuildInputs = [
      enumer
      go
      git
      cacert
      mockgen
    ];

    preBuild = ''
      make assets
    '';
  };

  tags = [
    "release"
  ];

  ldflags = [
    "-X github.com/evcc-io/evcc/server.Version=${version}"
    "-X github.com/evcc-io/evcc/server.Commit=${src.rev}"
    "-s"
    "-w"
  ];

  npmInstallFlags = [
    "--legacy-peer-deps"
  ];

  preBuild = ''
    make ui
  '';

  doCheck = !stdenv.isDarwin; # tries to bind to local network, doesn't work in darwin sandbox

  preCheck = ''
    # requires network access
    rm meter/template_test.go
  '';

  passthru = {
    tests = {
      inherit (nixosTests) evcc;
    };
    updateScript = nix-update-script { };
  };

  meta = with lib; {
    description = "EV Charge Controller";
    homepage = "https://evcc.io";
    changelog = "https://github.com/andig/evcc/releases/tag/${version}";
    license = licenses.mit;
    maintainers = with maintainers; [ hexa ];
  };
}
