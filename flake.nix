{
	description = "A simple Go package";

	# Nixpkgs / NixOS version to use.
	inputs.nixpkgs.id = "nixos";
	inputs.nixpkgs.type = "indirect";

	inputs.go-src.url = "github:CreeperHost/modpacksch-serverdownloader/golang";
	inputs.go-src.flake = false;


	outputs = { self, nixpkgs, go-src }:
		let

			# to work with older version of flakes
			lastModifiedDate = go-src.lastModifiedDate or go-src.lastModified or "19700101";

			# Generate a user-friendly version number.
			version = builtins.substring 0 8 lastModifiedDate;

			# System types to support.
			supportedSystems = [ "x86_64-linux" "x86_64-darwin" "aarch64-linux" "aarch64-darwin" ];

			# Helper function to generate an attrset '{ x86_64-linux = f "x86_64-linux"; ... }'.
			forAllSystems = nixpkgs.lib.genAttrs supportedSystems;

			# Nixpkgs instantiated for supported system types.
			nixpkgsFor = forAllSystems (system: import nixpkgs { inherit system; });

		in
		{

			# Provide some binary packages for selected system types.
			packages = forAllSystems (system:
				let
					pkgs = nixpkgsFor.${system};
				in
				{
					go-hello = pkgs.buildGoModule {
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

						vendorSha256 = "sha256-pQpattmS9VmO3ZIQUFn66az8GSmB4IvYhTTCFn6SUmo=";
					};
				});

			# The default package for 'nix build'. This makes sense if the
			# flake provides only one package or there is a clear "main"
			# package.
			defaultPackage = forAllSystems (system: self.packages.${system}.go-hello);
		};
}
