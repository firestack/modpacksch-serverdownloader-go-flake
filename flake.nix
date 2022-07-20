{
	description = "A simple Go package";

	# Nixpkgs / NixOS version to use.
	inputs.nixpkgs.id = "nixos";
	inputs.nixpkgs.type = "indirect";

	inputs.go-src.url = "github:CreeperHost/modpacksch-serverdownloader/golang";
	inputs.go-src.flake = false;

	inputs.flake-utils.url = "github:numtide/flake-utils";

	outputs = { self, nixpkgs, go-src, flake-utils }:
		let
			# to work with older version of flakes
			lastModifiedDate = go-src.lastModifiedDate or go-src.lastModified or "19700101";

			# Generate a user-friendly version number.
			version = builtins.substring 0 8 lastModifiedDate;
		in
		flake-utils.lib.eachDefaultSystem (system: let
			pkgs = nixpkgs.legacyPackages.${system};
			selfpkgs = self.packages.${system};
		in
		{

			# Provide some binary packages for selected system types.
			packages = {
				default = selfpkgs.modpacksch;

				modpacksch-server-downloader = pkgs.buildGoModule {
					pname = "ServerDownloader";
					inherit version;
					# In 'nix develop', we don't need a copy of the source tree
					# in the Nix store.
					src = go-src;

					# This hash locks the dependencies of this package. It is
					# necessary because of how Go requires network access to resolve
					# VCS.  See https://www.tweag.io/blog/2021-03-04-gomod2nix/ for
					# details. Normally one can build with a fake sha256 and rely on native Go
					# mechanisms to tell you what the hash should be or determine what
					# it should be "out-of-band" with other tooling (eg. gomod2nix).
					# To begin with it is recommended to set this, but one must
					# remeber to bump this hash when your dependencies change.
					#vendorSha256 = pkgs.lib.fakeSha256;

					vendorSha256 = "sha256-mq/wTuLf4PFDja7EaVGMs1/j6HkzEIwM1wVJAYiWtZs=";

					preConfigure = ''
						sed \
							-e "s/{{COMMITHASH}}/${go-src.rev}/" \
							-e "s/{{BUILDNAME}}/nix-build-${version}/" \
							-i main.go
					'';
				};

				modpacksch = pkgs.runCommand "modpacksch-server-downloader-wrapper"
					{ buildInputs = [ pkgs.makeBinaryWrapper ]; } ''
					makeWrapper ${selfpkgs.modpacksch-server-downloader}/bin/ServerDownloader $out/bin/modpacksch \
						--suffix PATH : ${pkgs.jre_headless}/bin
				'';
			};

			apps.modpacksch = flake-utils.lib.mkApp {
				drv = selfpkgs.modpacksch;
				name = "modpacksch";
			};

			apps.default = self.apps.${system}.modpacksch;

		});
}
