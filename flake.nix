{
  description = "DroidCam OBS plugin (local build)";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.11";

  outputs = { self, nixpkgs }:
    let
      system = "x86_64-linux";
      pkgs = import nixpkgs { inherit system; };
      lib = pkgs.lib;
    in
    {
      packages.${system}.droidcam-obs = pkgs.stdenv.mkDerivation (finalAttrs: {
        pname = "droidcam-obs";
        version = "2.4.1";

        src = ./.;
        nativeBuildInputs = [ pkgs.pkg-config ];

        buildInputs = [
          pkgs.libjpeg_turbo
          pkgs.libimobiledevice
          pkgs.libusbmuxd
          pkgs.libplist
          pkgs.obs-studio
          pkgs.ffmpeg
        ];

        preBuild = ''
          mkdir -p build
        '';

        makeFlags = [
          "ALLOW_STATIC=no"
          "JPEG_DIR=${lib.getDev pkgs.libjpeg_turbo}"
          "JPEG_LIB=${lib.getLib pkgs.libjpeg_turbo}/lib"
          "IMOBILEDEV_DIR=${lib.getDev pkgs.libimobiledevice}"
          "IMOBILEDEV_LIB=${lib.getLib pkgs.libimobiledevice}/lib"
          "LIBOBS_INCLUDES=${pkgs.obs-studio}/include/obs"
          "FFMPEG_INCLUDES=${lib.getDev pkgs.ffmpeg}/include"
          "LIBIMOBILEDEV=libimobiledevice-1.0"
          "CXXFLAGS=-DDEBUG"
        ];

        installPhase = ''
          runHook preInstall
          mkdir -p $out/lib/obs-plugins
          mkdir -p $out/share/obs/obs-plugins/droidcam-obs/locale
          
          cp build/droidcam-obs.so $out/lib/obs-plugins/
          cp -R ./data/locale/* $out/share/obs/obs-plugins/droidcam-obs/locale/
          runHook postInstall
        '';

        meta = {
          description = "DroidCam OBS";
          homepage = "https://github.com/dev47apps/droidcam-obs-plugin";
          license = lib.licenses.gpl2Plus;
          platforms = lib.platforms.linux;
        };
      });

      devShells.${system}.default = let
        drv = self.packages.${system}.droidcam-obs;
      in
      pkgs.mkShell {
        packages = [
          (pkgs.wrapOBS {
            plugins = [ drv ];
          })
        ];

        shellHook = ''
          echo "--- DroidCam OBS Dev Shell ---"
          echo "Plugin built at: ${drv}"
        '';
      };
    };
}
