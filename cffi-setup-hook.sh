# CL-CFFI can be configured through either a lisp var
# (cffi:*foreign-library-directories*) or through LD_LIBRARY_PATH. It feels more
# clean to do it through the lisp var (there’s a reason Nixpkgs stdenv doesn’t
# put packages’ /lib dirs in LLP by default), but that would mean some kind of
# init.lisp file you should load. That is a very ugly API for anything except
# building native binaries.
#
# P.S.: Am I correct in thinking that the /real/ solution would be to have
# cl-cffi use pkg-config, when available? That would fit neatly into nixpkgs
# stdenv and not require any of this.

# Add any dependency with a lib dir to LD_LIBRARY_PATH, because it’s the only
# way to get cl-cffi to find it.
clCffi_addToLdLibraryPath () {
	# This works with sb-alien:load-shared-object on Darwin.
	addToSearchPath "DYLD_LIBRARY_PATH" "$1/lib"
}

# I /think/ this needs to be registered on both host /and/ target offsets,
# because lisp dependencies can be called both at build time (= host, because
# our build time = the dependency’s host?) and at runtime (= target), in macros?
# Right? This stuff is so confusing. Anyway, this double registration is how
# Emacs does it for its elisp search path, which seems to be the closest analog.
# TODO: Confirm that this is true
addEnvHooks "$hostOffset" clCffi_addToLdLibraryPath
addEnvHooks "$targetOffset" clCffi_addToLdLibraryPath
