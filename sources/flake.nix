# Copyright © 2022–2024  Hraban Luyat
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU Affero General Public License as published
# by the Free Software Foundation, version 3 of the License.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU Affero General Public License for more details.
#
# You should have received a copy of the GNU Affero General Public License
# along with this program.  If not, see <https://www.gnu.org/licenses/>.

# !!!! THIS IS NOT AN ACTUAL FLAKE -- DO NOT USE !!!!!

# This is an internal trick I use for dependency management ONLY. The flake UI
# neatly solves some problems I had as a maintainer of this scope, but you can’t
# actually directly include this flake or you’ll end up downloading all inputs
# before doing anything useful. The lock file must first be passed through a
# fixed-output-derivation shim before you can do anything with it. Anyway long
# story short:

#  DO  NOT  USE  !!!!

{

  inputs = {

    flake-compat = {
      # Use my own fixed-output-derivation branch because I don’t want to
      # eval-time download any dependencies. Only when actually used. And I want
      # to be able to upload the source to cachix.
      url = "github:hraban/flake-compat/fixed-output";
      flake = false;
    };
    nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-unstable";

    # Lisp packages

    # Awkward: flake input names must start with a letter.
    x_1am = {
      url = "github:lmj/1am";
      flake = false;
    };
    x_3bmd = {
      url = "github:3b/3bmd";
      flake = false;
    };
    x_3d-math = {
      url = "git+https://codeberg.org/shinmera/3d-math.git";
      flake = false;
    };
    x_3d-vectors = {
      url = "git+https://codeberg.org/shinmera/3d-vectors.git";
      flake = false;
    };
    x_40ants-asdf-system = {
      url = "github:40ants/40ants-asdf-system";
      flake = false;
    };
    x_40ants-doc = {
      url = "github:40ants/doc";
      flake = false;
    };
    access = {
      url = "github:AccelerationNet/access";
      flake = false;
    };
    acclimation = {
      url = "github:robert-strandh/Acclimation";
      flake = false;
    };
    alexandria = {
      url = "git+https://gitlab.common-lisp.net/alexandria/alexandria";
      flake = false;
    };
    alien-ring = {
      url = "github:mateuszb/alien-ring";
      flake = false;
    };
    anaphora = {
      url = "github:spwhitton/anaphora";
      flake = false;
    };
    anypool = {
      url = "github:fukamachi/anypool";
      flake = false;
    };
    archive = {
      url = "github:sharplispers/archive";
      flake = false;
    };
    arnesi = {
      url = "github:AccelerationNet/arnesi";
      flake = false;
    };
    array-utils = {
      url = "git+https://codeberg.org/shinmera/array-utils.git";
      flake = false;
    };
    arrow-macros = {
      url = "github:hipeta/arrow-macros";
      flake = false;
    };
    asdf = {
      url = "git+https://gitlab.common-lisp.net/asdf/asdf";
      flake = false;
    };
    asdf-flv = {
      url = "github:didierverna/asdf-flv";
      flake = false;
    };
    asdf-system-connections = {
      url = "github:gwkkwg/asdf-system-connections";
      flake = false;
    };
    assoc-utils = {
      url = "github:fukamachi/assoc-utils";
      flake = false;
    };
    atomics = {
      url = "github:shinmera/atomics";
      flake = false;
    };
    babel = {
      url = "github:cl-babel/babel";
      flake = false;
    };
    blackbird = {
      url = "github:orthecreedence/blackbird";
      flake = false;
    };
    bordeaux-threads = {
      url = "github:sionescu/bordeaux-threads";
      flake = false;
    };
    # bordeaux-threads has a new API, and its master branch has introduced
    # deprecation warnings for the old API. This breaks compilation (as per the
    # CL standard apparently?), so provide this package for older downstream
    # systems which haven’t updated yet. Obviously dangerous if any other system
    # depends on bordeaux-threads v2 in your entire dependency graph.
    bordeaux-threads-v1 = {
      url = "github:sionescu/bordeaux-threads/042e3b05f614e33328ac73db79d744443fb5a86f";
      flake = false;
    };
    calispel = {
      url = "github:hawkir/calispel";
      flake = false;
    };
    cffi = {
      url = "github:cffi/cffi";
      flake = false;
    };
    chipz = {
      url = "github:sharplispers/chipz";
      flake = false;
    };
    chunga = {
      url = "github:edicl/chunga";
      flake = false;
    };
    circular-streams = {
      url = "github:fukamachi/circular-streams";
      flake = false;
    };
    cl-annot = {
      url = "github:m2ym/cl-annot";
      flake = false;
    };
    cl-ansi-text = {
      url = "github:pnathan/cl-ansi-text";
      flake = false;
    };
    cl-async = {
      url = "github:orthecreedence/cl-async";
      flake = false;
    };
    cl-base64 = {
      url = "sourcehut:~hraban/git.kpe.io-mirror/cl-base64";
      flake = false;
    };
    cl-change-case = {
      url = "github:rudolfochrist/cl-change-case";
      flake = false;
    };
    cl-colors = {
      url = "github:tpapp/cl-colors";
      flake = false;
    };
    cl-colors2 = {
      url = "git+https://codeberg.org/cage/cl-colors2.git";
      flake = false;
    };
    cl-containers = {
      url = "github:hraban/cl-containers";
      flake = false;
    };
    cl-cookie = {
      url = "github:fukamachi/cl-cookie";
      flake = false;
    };
    cl-coveralls = {
      url = "github:fukamachi/cl-coveralls";
      flake = false;
    };
    cl-custom-hash-table = {
      url = "github:metawilm/cl-custom-hash-table";
      flake = false;
    };
    cl-dbi = {
      url = "github:fukamachi/cl-dbi";
      flake = false;
    };
    cl-difflib = {
      url = "github:wiseman/cl-difflib";
      flake = false;
    };
    cl-dot = {
      url = "github:michaelw/cl-dot";
      flake = false;
    };
    cl-fad = {
      url = "github:edicl/cl-fad";
      flake = false;
    };
    cl-gopher = {
      url = "github:knusbaum/cl-gopher";
      flake = false;
    };
    cl-html-diff = {
      url = "github:wiseman/cl-html-diff";
      flake = false;
    };
    cl-interpol = {
      url = "github:edicl/cl-interpol";
      flake = false;
    };
    cl-isaac = {
      url = "github:thephoeron/cl-isaac";
      flake = false;
    };
    cl-json = {
      url = "github:sharplispers/cl-json";
      flake = false;
    };
    cl-libuv = {
      url = "github:orthecreedence/cl-libuv";
      flake = false;
    };
    cl-libxml2 = {
      # url = "github:archimag/cl-libxml2";
      # Temporarily point at my own fork while figuring out Darwin build. Could
      # also use Nix patches but this is easier for me to manage.
      url = "github:hraban/cl-libxml2/build/darwin";
      flake = false;
    };
    cl-locale = {
      url = "github:fukamachi/cl-locale";
      flake = false;
    };
    cl-markdown = {
      url = "github:hraban/cl-markdown";
      flake = false;
    };
    cl-mimeparse = {
      url = "github:mmontone/cl-mimeparse";
      flake = false;
    };
    cl-mock = {
      url = "github:Ferada/cl-mock";
      flake = false;
    };
    cl-plus-ssl = {
      url = "github:cl-plus-ssl/cl-plus-ssl";
      flake = false;
    };
    cl-ppcre = {
      url = "github:edicl/cl-ppcre";
      flake = false;
    };
    cl-prevalence = {
      url = "github:40ants/cl-prevalence/pull/27/head";
      flake = false;
    };
    cl-qrencode = {
      url = "github:jnjcc/cl-qrencode";
      flake = false;
    };
    cl-quickcheck = {
      url = "github:mcandre/cl-quickcheck";
      flake = false;
    };
    cl-reactive = {
      url = "github:nklein/cl-reactive";
      flake = false;
    };
    cl-redis = {
      url = "github:vseloved/cl-redis";
      flake = false;
    };
    cl-slice = {
      url = "github:tpapp/cl-slice";
      flake = false;
    };
    cl-speedy-queue = {
      url = "github:zkat/cl-speedy-queue";
      flake = false;
    };
    cl-sqlite = {
      url = "github:TeMPOraL/cl-sqlite";
      flake = false;
    };
    cl-strings = {
      url = "github:diogoalexandrefranco/cl-strings";
      flake = false;
    };
    cl-syntax = {
      url = "github:m2ym/cl-syntax";
      flake = false;
    };
    cl-tld = {
      url = "github:1u4nx/cl-tld";
      flake = false;
    };
    cl-tls = {
      url = "github:shrdlu68/cl-tls";
      flake = false;
    };
    cl-unicode = {
      url = "github:edicl/cl-unicode";
      flake = false;
    };
    cl-utilities = {
      url = "git+https://gitlab.common-lisp.net/cl-utilities/cl-utilities";
      flake = false;
    };
    cl-variates = {
      # Temporarily point at personal fork with some fixes
      # url = "git+https://gitlab.common-lisp.net/cl-variates/cl-variates";
      url = "github:hraban/cl-variates/build";
      flake = false;
    };
    cl-who = {
      url = "github:edicl/cl-who";
      flake = false;
    };
    clack = {
      url = "github:fukamachi/clack";
      flake = false;
    };
    closer-mop = {
      url = "git+https://codeberg.org/pcostanza/closer-mop";
      flake = false;
    };
    clss = {
      url = "git+https://codeberg.org/shinmera/clss.git";
      flake = false;
    };
    clunit = {
      url = "github:tgutu/clunit";
      flake = false;
    };
    clunit2 = {
      url = "git+https://codeberg.org/cage/clunit2.git";
      flake = false;
    };
    coalton = {
      url = "github:coalton-lang/coalton";
      flake = false;
    };
    collectors = {
      url = "github:AccelerationNet/collectors";
      flake = false;
    };
    colorize = {
      url = "github:kingcons/colorize";
      flake = false;
    };
    common-doc = {
      url = "github:CommonDoc/common-doc";
      flake = false;
    };
    common-html = {
      url = "github:CommonDoc/common-html";
      flake = false;
    };
    commondoc-markdown = {
      url = "github:40ants/commondoc-markdown";
      flake = false;
    };
    computable-reals = {
      url = "github:stylewarning/computable-reals";
      flake = false;
    };
    concrete-syntax-tree = {
      url = "github:robert-strandh/Concrete-Syntax-Tree";
      flake = false;
    };
    contextl = {
      url = "git+https://codeberg.org/pcostanza/contextl";
      flake = false;
    };
    data-lens = {
      url = "github:fiddlerwoaroof/data-lens";
      flake = false;
    };
    deflate = {
      url = "github:pmai/Deflate";
      flake = false;
    };
    dexador = {
      url = "github:fukamachi/dexador";
      flake = false;
    };
    dissect = {
      url = "git+https://codeberg.org/shinmera/dissect.git";
      flake = false;
    };
    djula = {
      url = "github:mmontone/djula";
      flake = false;
    };
    dns-client = {
      url = "git+https://codeberg.org/shinmera/dns-client.git";
      flake = false;
    };
    docs-builder = {
      url = "github:40ants/docs-builder";
      flake = false;
    };
    documentation-utils = {
      url = "git+https://codeberg.org/shinmera/documentation-utils.git";
      flake = false;
    };
    drakma = {
      url = "github:edicl/drakma";
      flake = false;
    };
    dynamic-classes = {
      url = "github:hraban/dynamic-classes";
      flake = false;
    };
    eager-future2 = {
      url = "git+https://gitlab.common-lisp.net/vsedach/eager-future2";
      flake = false;
    };
    easy-routes = {
      url = "github:mmontone/easy-routes";
      flake = false;
    };
    eclector = {
      url = "github:robert-strandh/eclector";
      flake = false;
    };
    enchant = {
      url = "github:tlikonen/cl-enchant";
      flake = false;
    };
    eos = {
      url = "github:adlai/Eos";
      flake = false;
    };
    esrap = {
      url = "github:scymtym/esrap";
      flake = false;
    };
    event-emitter = {
      url = "github:fukamachi/event-emitter";
      flake = false;
    };
    f-underscore = {
      url = "git+https://gitlab.common-lisp.net/bpm/f-underscore";
      flake = false;
    };
    fare-memoization = {
      url = "github:fare/fare-memoization";
      flake = false;
    };
    fare-mop = {
      url = "github:fare/fare-mop";
      flake = false;
    };
    fare-quasiquote = {
      url = "github:fare/fare-quasiquote";
      flake = false;
    };
    fare-utils = {
      url = "github:fare/fare-utils";
      flake = false;
    };
    fast-http = {
      url = "github:fukamachi/fast-http";
      flake = false;
    };
    fast-io = {
      url = "github:rpav/fast-io";
      flake = false;
    };
    fast-websocket = {
      url = "github:fukamachi/fast-websocket";
      flake = false;
    };
    femlisp = {
      url = "git://git.savannah.nongnu.org/femlisp.git";
      flake = false;
    };
    fiasco = {
      url = "github:capitaomorte/fiasco";
      flake = false;
    };
    find-port = {
      url = "github:eudoxia0/find-port";
      flake = false;
    };
    fiveam = {
      url = "github:lispci/fiveam";
      flake = false;
    };
    flexi-streams = {
      url = "github:edicl/flexi-streams";
      flake = false;
    };
    float-features = {
      url = "git+https://codeberg.org/shinmera/float-features.git";
      flake = false;
    };
    form-fiddle = {
      url = "git+https://codeberg.org/shinmera/form-fiddle.git";
      flake = false;
    };
    fset = {
      url = "github:slburson/fset";
      flake = false;
    };
    garbage-pools = {
      url = "github:archimag/garbage-pools";
      flake = false;
    };
    gettext = {
      url = "github:rotatef/gettext";
      flake = false;
    };
    global-vars = {
      url = "github:lmj/global-vars";
      flake = false;
    };
    hamcrest = {
      url = "github:40ants/cl-hamcrest";
      flake = false;
    };
    history-tree = {
      url = "github:atlas-engineer/history-tree";
      flake = false;
    };
    html-encode = rec {
      url = "http://beta.quicklisp.org/orphans/html-encode-1.2.tgz";
      flake = false;
    };
    html-entities = {
      url = "github:BnMcGn/html-entities";
      flake = false;
    };
    http-body = {
      url = "github:fukamachi/http-body";
      flake = false;
    };
    hu_dwim_asdf = {
      url = "github:hu-dwim/hu.dwim.asdf";
      flake = false;
    };
    hu_dwim_stefil = {
      url = "github:hu-dwim/hu.dwim.stefil";
      flake = false;
    };
    hunchentoot = {
      url = "github:edicl/hunchentoot";
      flake = false;
    };
    hunchentoot-errors = {
      url = "github:mmontone/hunchentoot-errors";
      flake = false;
    };
    idna = {
      url = "github:antifuchs/idna";
      flake = false;
    };
    ieee-floats = {
      url = "github:marijnh/ieee-floats";
      flake = false;
    };
    in-nomine = {
      url = "github:phoe/in-nomine";
      flake = false;
    };
    inferior-shell = {
      url = "github:fare/inferior-shell";
      flake = false;
    };
    infix-math = {
      url = "github:ruricolist/infix-math";
      flake = false;
    };
    introspect-environment = {
      url = "github:Bike/introspect-environment";
      flake = false;
    };
    ironclad = {
      url = "github:sharplispers/ironclad";
      flake = false;
    };
    iterate = {
      url = "git+https://gitlab.common-lisp.net/iterate/iterate";
      flake = false;
    };
    jonathan = {
      url = "github:Rudolph-Miller/jonathan";
      flake = false;
    };
    jpl-queues = {
      # upstream:
      # "tarball+https://www.thoughtcrime.us/software/jpl-queues/jpl-queues-0.1.tar.gz";
      # Switched to mirror on 2026/05/31 because upstream is unreachable.
      url = "git+https://gitlab.common-lisp.net/nyxt/jpl-queues";
      flake = false;
    };
    jpl-util = {
      url = "github:hawkir/cl-jpl-util";
      flake = false;
    };
    js = {
      url = "github:akapav/js";
      flake = false;
    };
    json-streams = {
      url = "github:rotatef/json-streams";
      flake = false;
    };
    jzon = {
      url = "github:Zulu-Inuoe/jzon";
      flake = false;
    };
    kmrcl = {
      url = "sourcehut:~hraban/git.kpe.io-mirror/kmrcl";
      flake = false;
    };
    lack = {
      url = "github:fukamachi/lack";
      flake = false;
    };
    lass = {
      url = "git+https://codeberg.org/shinmera/LASS.git";
      flake = false;
    };
    legion = {
      url = "github:fukamachi/legion";
      flake = false;
    };
    let-plus = {
      url = "github:tpapp/let-plus";
      flake = false;
    };
    lift = {
      url = "github:hraban/lift";
      flake = false;
    };
    lisp-namespace = {
      url = "github:guicho271828/lisp-namespace";
      flake = false;
    };
    lisp-unit = {
      url = "github:OdonataResearchLLC/lisp-unit";
      flake = false;
    };
    lisp-unit2 = {
      url = "github:AccelerationNet/lisp-unit2";
      flake = false;
    };
    lml2 = {
      url = "sourcehut:~hraban/git.kpe.io-mirror/lml2";
      flake = false;
    };
    local-time = {
      url = "github:dlowe-net/local-time";
      flake = false;
    };
    log4cl = {
      url = "github:sharplispers/log4cl";
      flake = false;
    };
    log4cl-extras = {
      url = "github:40ants/log4cl-extras";
      flake = false;
    };
    lparallel = {
      url = "github:sharplispers/lparallel";
      flake = false;
    };
    lquery = {
      url = "git+https://codeberg.org/shinmera/lquery.git";
      flake = false;
    };
    lw-compat = {
      url = "git+https://codeberg.org/pcostanza/lw-compat";
      flake = false;
    };
    map-set = {
      url = "github:stylewarning/map-set";
      flake = false;
    };
    marshal = {
      url = "github:wlbr/cl-marshal";
      flake = false;
    };
    md5 = {
      url = "github:pmai/md5";
      flake = false;
    };
    metabang-bind = {
      url = "github:hraban/metabang-bind";
      flake = false;
    };
    metacopy = {
      url = "github:hraban/metacopy";
      flake = false;
    };
    metatilities = {
      url = "github:hraban/metatilities";
      flake = false;
    };
    metatilities-base = {
      url = "github:hraban/metatilities-base";
      flake = false;
    };
    mgl-pax = {
      url = "github:melisgl/mgl-pax";
      flake = false;
    };
    misc-extensions = {
      url = "git+https://gitlab.common-lisp.net/misc-extensions/misc-extensions";
      flake = false;
    };
    moptilities = {
      url = "github:hraban/moptilities";
      flake = false;
    };
    mt19937 = {
      url = "git+https://gitlab.common-lisp.net/nyxt/mt19937";
      flake = false;
    };
    myway = {
      url = "github:fukamachi/myway";
      flake = false;
    };
    named-readtables = {
      url = "github:melisgl/named-readtables";
      flake = false;
    };
    nclasses = {
      url = "github:atlas-engineer/nclasses";
      flake = false;
    };
    nfiles = {
      url = "github:atlas-engineer/nfiles";
      flake = false;
    };
    ningle = {
      url = "github:fukamachi/ningle";
      flake = false;
    };
    nst = {
      url = "github:jphmrst/cl-nst";
      flake = false;
    };
    optima = {
      url = "github:m2ym/optima";
      flake = false;
    };
    org-sampler = {
      url = "github:jphmrst/cl-org-sampler";
      flake = false;
    };
    osicat = {
      url = "github:osicat/osicat";
      flake = false;
    };
    parachute = {
      url = "git+https://codeberg.org/shinmera/parachute.git";
      flake = false;
    };
    # TODO: Somehow create a versioned URL from this.
    parenscript = {
      url = "tarball+https://common-lisp.net/project/parenscript/release/parenscript-latest.tgz";
      flake = false;
    };
    parse-declarations = {
      url = "git+https://gitlab.common-lisp.net/parse-declarations/parse-declarations";
      flake = false;
    };
    parse-js = {
      url = "github:marijnh/parse-js";
      flake = false;
    };
    parse-number = {
      url = "github:sharplispers/parse-number";
      flake = false;
    };
    parser-combinators = {
      url = "github:Ramarren/cl-parser-combinators";
      flake = false;
    };
    path-parse = {
      url = "github:eudoxia0/path-parse";
      flake = false;
    };
    plump = {
      url = "git+https://codeberg.org/shinmera/plump.git";
      flake = false;
    };
    proc-parse = {
      url = "github:fukamachi/proc-parse";
      flake = false;
    };
    prove = {
      url = "github:fukamachi/prove";
      flake = false;
    };
    ptester = {
      url = "sourcehut:~hraban/git.kpe.io-mirror/ptester";
      flake = false;
    };
    punycode = {
      url = "git+https://codeberg.org/shinmera/punycode.git";
      flake = false;
    };
    puri = {
      url = "git+https://gitlab.common-lisp.net/clpm/puri";
      flake = false;
    };
    pythonic-string-reader = {
      url = "github:smithzvk/pythonic-string-reader";
      flake = false;
    };
    quickhull = {
      url = "github:Shirakumo/quickhull";
      flake = false;
    };
    quri = {
      url = "github:fukamachi/quri";
      flake = false;
    };
    reblocks = {
      url = "github:40ants/reblocks";
      flake = false;
    };
    reblocks-parenscript = {
      url = "github:40ants/reblocks-parenscript";
      flake = false;
    };
    reblocks-ui = {
      url = "github:40ants/reblocks-ui";
      flake = false;
    };
    reblocks-websocket = {
      url = "github:40ants/reblocks-websocket";
      flake = false;
    };
    rfc2388 = {
      url = "git+https://gitlab.common-lisp.net/rfc2388/rfc2388";
      flake = false;
    };
    routes = {
      url = "github:archimag/cl-routes";
      flake = false;
    };
    rove = {
      url = "github:fukamachi/rove";
      flake = false;
    };
    rt = {
      url = "sourcehut:~hraban/git.kpe.io-mirror/rt";
      flake = false;
    };
    rutils = {
      url = "github:vseloved/rutils";
      flake = false;
    };
    s-sysdeps = {
      url = "github:svenvc/s-sysdeps/pull/3/head";
      flake = false;
    };
    s-xml = {
      url = "git+https://gitlab.common-lisp.net/s-xml/s-xml";
      flake = false;
    };
    # TODO: Somehow create a versioned URL from this.
    salza2 = {
      url = "tarball+http://www.xach.com/lisp/salza2.tgz";
      flake = false;
    };
    serapeum = {
      url = "github:ruricolist/serapeum";
      flake = false;
    };
    sha1 = {
      url = "github:massung/sha1";
      flake = false;
    };
    shasht = {
      url = "github:yitzchak/shasht";
      flake = false;
    };
    should-test = {
      url = "github:vseloved/should-test";
      flake = false;
    };
    simple-date-time = {
      url = "github:quek/simple-date-time";
      flake = false;
    };
    slime = {
      url = "github:slime/slime";
      flake = false;
    };
    sly = {
      url = "github:joaotavora/sly";
      flake = false;
    };
    smart-buffer = {
      url = "github:fukamachi/smart-buffer";
      flake = false;
    };
    spinneret = {
      url = "github:ruricolist/spinneret";
      flake = false;
    };
    split-sequence = {
      url = "github:sharplispers/split-sequence";
      flake = false;
    };
    static-vectors = {
      url = "github:sionescu/static-vectors";
      flake = false;
    };
    stefil = {
      url = "git+https://gitlab.common-lisp.net/stefil/stefil";
      flake = false;
    };
    stem = {
      url = "github:hanshuebner/stem";
      flake = false;
    };
    str = {
      url = "github:vindarel/cl-str";
      flake = false;
    };
    string-case = {
      url = "github:pkhuong/string-case";
      flake = false;
    };
    symbol-munger = {
      url = "github:AccelerationNet/symbol-munger";
      flake = false;
    };
    tmpdir = {
      url = "github:moderninterpreters/tmpdir";
      flake = false;
    };
    trivia = {
      url = "github:guicho271828/trivia";
      flake = false;
    };
    trivial-arguments = {
      url = "git+https://codeberg.org/shinmera/trivial-arguments.git";
      flake = false;
    };
    trivial-backtrace = {
      url = "git+https://gitlab.common-lisp.net/trivial-backtrace/trivial-backtrace";
      flake = false;
    };
    trivial-benchmark = {
      url = "git+https://codeberg.org/shinmera/trivial-benchmark.git";
      flake = false;
    };
    trivial-cltl2 = {
      url = "github:Zulu-Inuoe/trivial-cltl2";
      flake = false;
    };
    trivial-custom-debugger = {
      url = "github:phoe/trivial-custom-debugger";
      flake = false;
    };
    trivial-do = {
      url = "github:yitzchak/trivial-do";
      flake = false;
    };
    trivial-extract = {
      url = "github:eudoxia0/trivial-extract";
      flake = false;
    };
    trivial-features = {
      url = "github:trivial-features/trivial-features";
      flake = false;
    };
    trivial-file-size = {
      url = "github:ruricolist/trivial-file-size";
      flake = false;
    };
    trivial-garbage = {
      url = "github:trivial-garbage/trivial-garbage";
      flake = false;
    };
    trivial-gray-streams = {
      url = "github:trivial-gray-streams/trivial-gray-streams";
      flake = false;
    };
    trivial-indent = {
      url = "git+https://codeberg.org/shinmera/trivial-indent.git";
      flake = false;
    };
    trivial-macroexpand-all = {
      url = "github:cbaggers/trivial-macroexpand-all";
      flake = false;
    };
    trivial-mimes = {
      url = "git+https://codeberg.org/shinmera/trivial-mimes.git";
      flake = false;
    };
    trivial-open-browser = {
      url = "github:eudoxia0/trivial-open-browser";
      flake = false;
    };
    trivial-package-local-nicknames = {
      url = "github:phoe/trivial-package-local-nicknames";
      flake = false;
    };
    trivial-rfc-1123 = {
      url = "github:stacksmith/trivial-rfc-1123";
      flake = false;
    };
    trivial-shell = {
      url = "github:hraban/trivial-shell";
      flake = false;
    };
    trivial-sockets = {
      url = "github:usocket/trivial-sockets";
      flake = false;
    };
    trivial-timeout = {
      url = "github:hraban/trivial-timeout";
      flake = false;
    };
    trivial-types = {
      url = "github:m2ym/trivial-types";
      flake = false;
    };
    trivial-utf-8 = {
      url = "git+https://gitlab.common-lisp.net/trivial-utf-8/trivial-utf-8";
      flake = false;
    };
    trivial-with-current-source-form = {
      url = "github:scymtym/trivial-with-current-source-form";
      flake = false;
    };
    try = {
      url = "github:melisgl/try";
      flake = false;
    };
    type-i = {
      url = "github:guicho271828/type-i";
      flake = false;
    };
    type-templates = {
      url = "git+https://codeberg.org/shinmera/type-templates.git";
      flake = false;
    };
    typo = {
      url = "github:marcoheisig/Typo";
      flake = false;
    };
    unit-test = {
      url = "github:hanshuebner/unit-test";
      flake = false;
    };
    unix-options = {
      url = "github:astine/unix-options";
      flake = false;
    };
    usocket = {
      url = "github:usocket/usocket";
      flake = false;
    };
    uuid = {
      url = "github:dardoria/uuid";
      flake = false;
    };
    vom = {
      url = "github:orthecreedence/vom";
      flake = false;
    };
    websocket-driver = {
      url = "github:fukamachi/websocket-driver";
      flake = false;
    };
    which = {
      url = "github:eudoxia0/which";
      flake = false;
    };
    wild-package-inferred-system = {
      url = "github:privet-kitty/wild-package-inferred-system";
      flake = false;
    };
    # TODO: Somehow create a versioned URL from this.
    with-output-to-stream = {
      url = "tarball+https://tarballs.hexstreamsoft.com/libraries/latest/with-output-to-stream_latest.tar.gz";
      flake = false;
    };
    wu-decimal = {
      url = "github:Wukix/wu-decimal";
      flake = false;
    };
    xlunit = {
      url = "sourcehut:~hraban/git.kpe.io-mirror/xlunit";
      flake = false;
    };
    xml-emitter = {
      url = "github:VitoVan/xml-emitter";
      flake = false;
    };
    xsubseq = {
      url = "github:fukamachi/xsubseq";
      flake = false;
    };
    yacc = {
      url = "github:jech/cl-yacc";
      flake = false;
    };
    yason = {
      url = "github:phmarek/yason";
      flake = false;
    };
    zip = {
      url = "github:bluelisp/zip";
      flake = false;
    };
    # TODO: Somehow create a versioned URL from this.
    zpng = {
      url = "tarball+https://www.xach.com/lisp/zpng.tgz";
      flake = false;
    };
  };

  # DO NOT USE!!!
  outputs =
    inputs@{ nixpkgs, ... }:
    {
      inherit inputs;
    };
}

#  DO NOT USE!!!
