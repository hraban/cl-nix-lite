# Copyright © 2022–2023  Hraban Luyat
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

    # Lisp packages

    "1am" = {
      url = "github:lmj/1am";
      flake = false;
    };
    "3bmd" = {
      url = "github:3b/3bmd";
      flake = false;
    };
    "3d-math" = {
      url = "github:Shinmera/3d-math";
      flake = false;
    };
    "3d-vectors" = {
      url = "github:Shinmera/3d-vectors";
      flake = false;
    };
    "40ants-asdf-system" = {
      url = "github:40ants/40ants-asdf-system";
      flake = false;
    };
    "40ants-doc" = {
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
      url = "gitlab:alexandria/alexandria?host=gitlab.common-lisp.net";
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
      url = "github:Shinmera/array-utils";
      flake = false;
    };
    arrow-macros = {
      url = "github:hipeta/arrow-macros";
      flake = false;
    };
    asdf = {
      url = "gitlab:asdf/asdf?host=gitlab.common-lisp.net";
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
      url = "git+http://git.kpe.io/cl-base64.git";
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
    "cl+ssl" = {
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
      url = "gitlab:cl-utilities/cl-utilities?host=gitlab.common-lisp.net";
      flake = false;
    };
    cl-variates = {
      # Temporarily point at personal fork with some fixes
      # url = "gitlab:cl-variates/cl-variates?host=gitlab.common-lisp.net";
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
      url = "github:pcostanza/closer-mop";
      flake = false;
    };
    clss = {
      url = "github:Shinmera/clss";
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
    concrete-syntax-tree = {
      url = "github:robert-strandh/Concrete-Syntax-Tree";
      flake = false;
    };
    contextl = {
      url = "github:pcostanza/contextl";
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
      url = "github:Shinmera/dissect";
      flake = false;
    };
    djula = {
      url = "github:mmontone/djula";
      flake = false;
    };
    dns-client = {
      url = "github:Shinmera/dns-client";
      flake = false;
    };
    docs-builder = {
      url = "github:40ants/docs-builder";
      flake = false;
    };
    documentation-utils = {
      url = "github:Shinmera/documentation-utils";
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
      url = "gitlab:vsedach/eager-future2?host=gitlab.common-lisp.net";
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
    f-underscore = {
      url = "gitlab:bpm/f-underscore?host=gitlab.common-lisp.net";
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
      url = "github:Shinmera/float-features";
      flake = false;
    };
    form-fiddle = {
      url = "github:Shinmera/form-fiddle";
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
    "hu.dwim.asdf" = {
      url = "github:hu-dwim/hu.dwim.asdf";
      flake = false;
    };
    "hu.dwim.stefil" = {
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
      url =  "gitlab:iterate/iterate?host=gitlab.common-lisp.net";
      flake = false;
    };
    jonathan = {
      url = "github:Rudolph-Miller/jonathan";
      flake = false;
    };
    jpl-queues = {
      url = "tarball+https://www.thoughtcrime.us/software/jpl-queues/jpl-queues-0.1.tar.gz";
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
      url = "git+http://git.kpe.io/kmrcl.git";
      flake = false;
    };
    lack = {
      url = "github:fukamachi/lack";
      flake = false;
    };
    lass = {
      url = "github:Shinmera/LASS";
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
      url = "git+http://git.kpe.io/lml2.git";
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
      url = "github:Shinmera/lquery";
      flake = false;
    };
    lw-compat = {
      url = "github:pcostanza/lw-compat";
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
      url = "gitlab:misc-extensions/misc-extensions?host=gitlab.common-lisp.net";
      flake = false;
    };
    moptilities = {
      url = "github:hraban/moptilities";
      flake = false;
    };
    mt19937 = {
      url = "gitlab:nyxt/mt19937?host=gitlab.common-lisp.net";
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
    optima = {
      url = "github:m2ym/optima";
      flake = false;
    };
    osicat = {
      url = "github:osicat/osicat";
      flake = false;
    };
    parachute = {
      url = "github:Shinmera/parachute";
      flake = false;
    };
    # TODO: Somehow create a versioned URL from this.
    parenscript = {
      url = "tarball+https://common-lisp.net/project/parenscript/release/parenscript-latest.tgz";
      flake = false;
    };
    parse-declarations = {
      url = "gitlab:parse-declarations/parse-declarations?host=gitlab.common-lisp.net";
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
      url = "github:Shinmera/plump";
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
      url = "git+http://git.kpe.io/ptester.git";
      flake = false;
    };
    punycode = {
      url = "github:Shinmera/punycode";
      flake = false;
    };
    puri = {
      url = "gitlab:clpm/puri?host=gitlab.common-lisp.net";
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
    rfc2388 = {
      url = "gitlab:rfc2388/rfc2388?host=gitlab.common-lisp.net";
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
      url = "git+http://git.kpe.io/rt.git";
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
      url = "gitlab:s-xml/s-xml?host=gitlab.common-lisp.net";
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
      url = "gitlab:stefil/stefil?host=gitlab.common-lisp.net";
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
      url = "github:Shinmera/trivial-arguments";
      flake = false;
    };
    trivial-backtrace = {
      url =  "gitlab:trivial-backtrace/trivial-backtrace?host=gitlab.common-lisp.net";
      flake = false;
    };
    trivial-benchmark = {
      url = "github:Shinmera/trivial-benchmark";
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
      url = "github:Shinmera/trivial-indent";
      flake = false;
    };
    trivial-macroexpand-all = {
      url = "github:cbaggers/trivial-macroexpand-all";
      flake = false;
    };
    trivial-mimes = {
      url = "github:Shinmera/trivial-mimes";
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
      url = "gitlab:trivial-utf-8/trivial-utf-8?host=gitlab.common-lisp.net";
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
      url = "github:Shinmera/type-templates";
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
      url = "git+http://git.kpe.io/xlunit.git";
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
  outputs = inputs@{ nixpkgs, ... }:
    {
      inherit inputs;
    };
}

#  DO NOT USE!!!
