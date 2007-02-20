package Jemplate;
use 5.006001;
use strict;
use warnings;
use Template 2.14;
use Getopt::Long;

our $VERSION = '0.20';

use Jemplate::Parser;

#-------------------------------------------------------------------------------
sub usage {
    <<'...';
Usage:
    jemplate --runtime
    jemplate (--compile|--list) [options] template-list

For more information use:
    perldoc jemplate
...
}

sub main {
    my $class = shift;

    my @argv = @_;

    my ($command, $template_options, $jemplate_options) = get_options(@argv);

    if ($command eq 'runtime') {
        print STDOUT runtime_source_code();
        return;
    }

    my $templates = make_file_list(@argv);
    print_usage_and_exit() unless @$templates;

    if ($command eq 'list') {
        foreach (@$templates) {
            print STDOUT $_->{short} . "\n";
        }
        return;
    }

    if ($command eq 'compile') {
        my $jemplate = Jemplate->new(%$template_options);
        print STDOUT $jemplate->_preamble;
        foreach my $template (@$templates) {
            my $content = slurp($template->{full});
            if ($content) {
                print STDOUT $jemplate->compile_template_content(
                    $content,
                    $template->{short},
                );
            }
        }
        return;
    }

    print_usage_and_exit();
}

sub get_options {
    local @ARGV = @_;

    my $runtime = 0;
    my $compile = 0;
    my $list = 0;

    my $start_tag = exists $ENV{JEMPLATE_START_TAG}
        ? $ENV{JEMPLATE_START_TAG}
        : undef;
    my $end_tag = exists $ENV{JEMPLATE_END_TAG}
        ? $ENV{JEMPLATE_END_TAG}
        : undef;
    my $pre_chomp = exists $ENV{JEMPLATE_PRE_CHOMP}
        ? $ENV{JEMPLATE_PRE_CHOMP}
        : undef;
    my $post_chomp = exists $ENV{JEMPLATE_POST_CHOMP}
        ? $ENV{JEMPLATE_POST_CHOMP}
        : undef;
    my $trim = exists $ENV{JEMPLATE_TRIM}
        ? $ENV{JEMPLATE_TRIM}
        : undef;
    my $anycase = exists $ENV{JEMPLATE_ANYCASE}
        ? $ENV{JEMPLATE_ANYCASE}
        : undef;
    my $eval_javascript = exists $ENV{JEMPLATE_EVAL_JAVASCRIPT}
        ? $ENV{JEMPLATE_EVAL_JAVASCRIPT}
        : 1;

    my $source = 0;

    GetOptions(
        "compile|c"     => \$compile,
        "list|l"        => \$list,
        "runtime|r"     => \$runtime,

        "start-tag=s"   => \$start_tag,
        "end-tag=s"     => \$end_tag,
        "pre-chomp"     => \$pre_chomp,
        "post-chomp"    => \$post_chomp,
        "any-case"      => \$anycase,
        "eval!"         => \$eval_javascript,

        "source|s"      => \$source,

        "help|?"        => \&print_usage_and_exit,
    ) or print_usage_and_exit();

    my $command =
        $runtime ? 'runtime' :
        $compile ? 'compile' :
        $list ? 'list' :
        print_usage_and_exit();

    my $options = {};
    $options->{START_TAG} = $start_tag if defined $start_tag;
    $options->{END_TAG} = $end_tag if defined $end_tag;
    $options->{PRE_CHOMP} = $pre_chomp if defined $pre_chomp;
    $options->{POST_CHOMP} = $post_chomp if defined $post_chomp;
    $options->{TRIM} = $trim if defined $trim;
    $options->{ANYCASE} = $anycase if defined $anycase;
    $options->{EVAL_JAVASCRIPT} = $eval_javascript if defined $eval_javascript;

    return (
        $command,
        $options,
        {source => $source},
    );
}


sub slurp {
    my $filepath = shift;
    open(F, '<', $filepath) or die "Can't open '$filepath' for input:\n$!";
    my $contents = do {local $/; <F>};
    close(F);
    return $contents;
}

sub recurse_dir {
    require File::Find::Rule;

    my $dir = shift;
    my @files;
    foreach ( File::Find::Rule->file->in( $dir ) ) {
        # don't include .hidden files
        unless ($_ =~ '\/\.') { push(@files, $_); }
    }
    return @files;
}

sub make_file_list {
    my @args = @_;

    my @list;

    foreach my $arg (@args) {
        unless (-e $arg) { next; } # file exists
        unless (-s $arg) { next; } # file size > 0

        if (-d $arg) {
            foreach my $full ( recurse_dir($arg) ) {
                $full =~ /$arg(\/|)(.*)/;
                my $short = $2;
                push(@list, {full=>$full, short=>$short} );
            }
        }
        else {
            my $full = $arg;
            my $short = $full;
            $short =~ s/.*[\/\\]//;
            push(@list, {full=>$arg, short=>$short} );
        }
    }

    return [ sort { $a->{short} cmp $b->{short} } @list ];
}

sub print_usage_and_exit {
    print STDOUT usage();
    exit;
}

sub runtime_source_code {
    return <<'...';
/*------------------------------------------------------------------------------
Jemplate - Template Toolkit for JavaScript

DESCRIPTION - This module provides the runtime JavaScript support for
compiled Jemplate templates.

AUTHOR - Ingy döt Net <ingy@cpan.org>

Copyright 2006 Ingy döt Net. All Rights Reserved.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.
------------------------------------------------------------------------------*/

//------------------------------------------------------------------------------
// Main Jemplate class
//------------------------------------------------------------------------------

if (typeof Jemplate == 'undefined') {
    Jemplate = function() {
        this.init.apply(this, arguments);
    };
}

if (! Jemplate.templateMap)
    Jemplate.templateMap = {};

Jemplate.process = function() {
    var jemplate = new Jemplate();
    return jemplate.process.apply(jemplate, arguments);
}

proto = Jemplate.prototype;

proto.init = function(config) {
    this.config = config ||
    {
        AUTO_RESET: true,
        BLOCKS: {},
        CONTEXT: null,
        DEBUG_UNDEF: false,
        DEFAULT: null,
        ERROR: null,
        EVAL_JAVASCRIPT: false,
        FILTERS: {},
        INCLUDE_PATH: [''],
        INTERPOLATE: false,
        OUTPUT: null,
        PLUGINS: {},
        POST_PROCESS: [],
        PRE_PROCESS: [],
        PROCESS: null,
        RECURSION: false,
        STASH: null,
        TOLERANT: null,
        VARIABLES: {},
        WRAPPER: []
    };
}

proto.process = function(template, data, output) {
    var context = this.config.CONTEXT || new Jemplate.Context();
    context.config = this.config;

    context.stash = this.config.STASH || new Jemplate.Stash();
    context.stash.__config__ = this.config;

    context.__filter__ = new Jemplate.Filter();
    context.__filter__.config = this.config;

    context.__plugin__ = new Jemplate.Plugin();
    context.__plugin__.config = this.config;

    var result;

    var proc = function(input) {
        try {
            result = context.process(template, input);
        }
        catch(e) {
            if (! String(e).match(/Jemplate\.STOP\n/))
                throw(e);
            result = e.toString().replace(/Jemplate\.STOP\n/, '');
        }

        if (typeof output == 'undefined')
            return result;
        if (typeof output == 'function') {
            output(result);
            return;
        }
        if (typeof(output) == 'string' || output instanceof String) {
            if (output.match(/^#[\w\-]+$/)) {
                var id = output.replace(/^#/, '');
                var element = document.getElementById(id);
                if (typeof element == 'undefined')
                    throw('No element found with id="' + id + '"');
                element.innerHTML = result;
                return;
            }
        }
        else {
            output.innerHTML = result;
            return;
        }

        throw("Invalid arguments in call to Jemplate.process");

        return 1;
    }

    if (typeof data == 'function')
        data = data();
    else if (typeof data == 'string') {
        Ajax.get(data, function(r) { proc(JSON.parse(r)) });
        return;
    }

    return proc(data);
}

//------------------------------------------------------------------------------
// Jemplate.Context class
//------------------------------------------------------------------------------
if (typeof Jemplate.Context == 'undefined')
    Jemplate.Context = function() {};

proto = Jemplate.Context.prototype;

proto.include = function(template, args) {
    return this.process(template, args, true);
}

proto.process = function(template, args, localise) {
    if (localise)
        this.stash.clone(args);
    else
        this.stash.update(args);
    var func = Jemplate.templateMap[template];
    if (typeof func == 'undefined')
        throw('No Jemplate template named "' + template + '" available');
    var output = func(this);
    if (localise)
        this.stash.declone();
    return output;
}

proto.set_error = function(error, output) {
    this._error = [error, output];
    return error;
}

proto.plugin = function(name, args) {
    if (typeof name == 'undefined')
        throw "Unknown plugin name ':" + name + "'";

    // The Context object (this) is passed as the first argument to the plugin.
    return new window[name](this, args);
}

proto.filter = function(text, name, args) {
    if (name == 'null')
        name = "null_filter";
    if (typeof this.__filter__.filters[name] == "function")
        return this.__filter__.filters[name](text, args, this);
    else
        throw "Unknown filter name ':" + name + "'";
}

//------------------------------------------------------------------------------
// Jemplate.Plugin class
//------------------------------------------------------------------------------
if (typeof Jemplate.Plugin == 'undefined') {
    Jemplate.Plugin = function() { };
}

proto = Jemplate.Plugin.prototype;

proto.plugins = {};

//------------------------------------------------------------------------------
// Jemplate.Filter class
//------------------------------------------------------------------------------
if (typeof Jemplate.Filter == 'undefined') {
    Jemplate.Filter = function() { };
}

proto = Jemplate.Filter.prototype;

proto.filters = {};

proto.filters.null_filter = function(text) {
    return '';
}

proto.filters.upper = function(text) {
    return text.toUpperCase();
}

proto.filters.lower = function(text) {
    return text.toLowerCase();
}

proto.filters.ucfirst = function(text) {
    var first = text.charAt(0);
    var rest = text.substr(1);
    return first.toUpperCase() + rest;
}

proto.filters.lcfirst = function(text) {
    var first = text.charAt(0);
    var rest = text.substr(1);
    return first.toLowerCase() + rest;
}

proto.filters.trim = function(text) {
    return text.replace( /^\s+/g, "" ).replace( /\s+$/g, "" );
}

proto.filters.collapse = function(text) {
    return text.replace( /^\s+/g, "" ).replace( /\s+$/g, "" ).replace(/\s+/, " ");
}

proto.filters.html = function(text) {
    text = text.replace(/&/g, '&amp;');
    text = text.replace(/</g, '&lt;');
    text = text.replace(/>/g, '&gt;');
    text = text.replace(/"/g, '&quot;'); // " end quote for emacs
    return text;
}

proto.filters.html_para = function(text) {
    var lines = text.split(/(?:\r?\n){2,}/);
    return "<p>\n" + lines.join("\n</p>\n\n<p>\n") + "</p>\n";
}

proto.filters.html_break = function(text) {
    return text.replace(/(\r?\n){2,}/g, "$1<br />$1<br />$1");
}

proto.filters.html_line_break = function(text) {
    return text.replace(/(\r?\n)/g, "$1<br />$1");
}

proto.filters.uri = function(text) {
    return encodeURI(text);
}

proto.filters.indent = function(text, args) {
    var pad = args[0];
    if (! text) return;
    if (typeof pad == 'undefined')
        pad = 4;

    var finalpad = '';
    if (typeof pad == 'number' || String(pad).match(/^\d$/)) {
        for (var i = 0; i < pad; i++) {
            finalpad += ' ';
        }
    } else {
        finalpad = pad;
    }
    var output = text.replace(/^/gm, finalpad);
    return output;
}

proto.filters.truncate = function(text, args) {
    var len = args[0];
    if (! text) return;
    if (! len)
        len = 32;
    // This should probably be <=, but TT just uses <
    if (text.length < len)
        return text;
    var newlen = len - 3;
    return text.substr(0,newlen) + '...';
}

proto.filters.repeat = function(text, iter) {
    if (! text) return;
    if (! iter || iter == 0)
        iter = 1;
    if (iter == 1) return text

    var output = text;
    for (var i = 1; i < iter; i++) {
        output += text;
    }
    return output;
}

proto.filters.replace = function(text, args) {
    if (! text) return;
    var re_search = args[0];
    var text_replace = args[1];
    if (! re_search)
        re_search = '';
    if (! text_replace)
        text_replace = '';
    var re = new RegExp(re_search, 'g');
    return text.replace(re, text_replace);
}

//------------------------------------------------------------------------------
// Jemplate.Stash class
//------------------------------------------------------------------------------
if (typeof Jemplate.Stash == 'undefined') {
    Jemplate.Stash = function() {
        this.data = {};
    };
}

proto = Jemplate.Stash.prototype;

proto.clone = function(args) {
    var data = this.data;
    this.data = {};
    this.update(data);
    this.update(args);
    this.data._PARENT = data;
}

proto.declone = function(args) {
    this.data = this.data._PARENT || this.data;
}

proto.update = function(args) {
    if (typeof args == 'undefined') return;
    for (var key in args) {
        var value = args[key];
        this.set(key, value);
    }
}

proto.get = function(key) {
    var root = this.data;
    if (key instanceof Array) {
        for (var i = 0; i < key.length; i += 2) {
            var args = key.slice(i, i+2);
            args.unshift(root);
            value = this._dotop.apply(this, args);
            if (typeof value == 'undefined')
                break;
            root = value;
        }
    }
    else {
        value = this._dotop(root, key);
    }

    if (typeof value == 'undefined') {
        if (this.__config__.DEBUG_UNDEF)
            throw("undefined value found while using DEGUG_UNDEF");
        value = '';
    }

    return value;
}

proto.set = function(key, value, set_default) {
    if (key instanceof Array) {
        var data = this.get(key[0]) || {};
        key = key[2];
    }
    else {
        data = this.data;
    }
    if (! (set_default && (typeof data[key] != 'undefined')))
        data[key] = value;
}

proto._dotop = function(root, item, args) {
    if (typeof item == 'undefined' ||
        typeof item == 'string' && item.match(/^[\._]/)) {
        return undefined;
    }

    if ((! args) &&
        (typeof root == 'object') &&
        (!(root instanceof Array) || (typeof item == 'number')) &&
        (typeof root[item] != 'undefined')) {
        var value = root[item];
        if (typeof value == 'function')
            value = value.apply(root);
        return value;
    }

    if (typeof root == 'string' && this.string_functions[item])
        return this.string_functions[item](root, args);
    if (root instanceof Array && this.list_functions[item])
        return this.list_functions[item](root, args);
    if (typeof root == 'object' && this.hash_functions[item])
        return this.hash_functions[item](root, args);
    if (typeof root[item] == 'function')
        return root[item].apply(root, args);

    return undefined;
}

proto.string_functions = {};

// chunk(size)     negative size chunks from end
proto.string_functions.chunk = function(string, args) {
    var size = args[0];
    var list = new Array();
    if (! size)
        size = 1;
    if (size < 0) {
        size = 0 - size;
        for (i = string.length - size; i >= 0; i = i - size)
            list.unshift(string.substr(i, size));
        if (string.length % size)
            list.unshift(string.substr(0, string.length % size));
    }
    else
        for (i = 0; i < string.length; i = i + size)
            list.push(string.substr(i, size));
    return list;
}

// defined         is value defined?
proto.string_functions.defined = function(string) {
    return 1;
}

// hash            treat as single-element hash with key value
proto.string_functions.hash = function(string) {
    return { 'value': string };
}

// length          length of string representation
proto.string_functions.length = function(string) {
    return string.length;
}

// list            treat as single-item list
proto.string_functions.list = function(string) {
    return [ string ];
}

// match(re)       get list of matches
proto.string_functions.match = function(string, args) {
    var regexp = new RegExp(args[0], 'gm');
    var list = string.match(regexp);
    return list;
}

// repeat(n)       repeated n times
proto.string_functions.repeat = function(string, args) {
    var n = args[0] || 1;
    var output = '';
    for (var i = 0; i < n; i++) {
        output += string;
    }
    return output;
}

// replace(re, sub)    replace instances of re with sub
proto.string_functions.replace = function(string, args) {
    var regexp = new RegExp(args[0], 'gm');
    var sub = args[1];
    if (! sub)
        sub  = '';
    var output = string.replace(regexp, sub);
    return output;
}

// search(re)      true if value matches re
proto.string_functions.search = function(string, args) {
    var regexp = new RegExp(args[0]);
    return (string.search(regexp) >= 0) ? 1 : 0;
}

// size            returns 1, as if a single-item list
proto.string_functions.size = function(string) {
    return 1;
}

// split(re)       split string on re
proto.string_functions.split = function(string, args) {
    var regexp = new RegExp(args[0]);
    var list = string.split(regexp);
    return list;
}



proto.list_functions = {};

proto.list_functions.join = function(list, args) {
    return list.join(args[0]);
};

proto.list_functions.sort = function(list,key) {
    if( typeof(key) != 'undefined' && key != "" ) {
        // we probably have a list of hashes
        // and need to sort based on hash key
        return list.sort(
            function(a,b) {
                if( a[key] == b[key] ) {
                    return 0;
                }
                else if( a[key] > b[key] ) {
                    return 1;
                }
                else {
                    return -1;
                }
            }
        );
    }
    return list.sort();
}

proto.list_functions.nsort = function(list) {
    return list.sort(function(a, b) { return (a-b) });
}

proto.list_functions.grep = function(list, args) {
    var regexp = new RegExp(args[0]);
    var result = [];
    for (var i = 0; i < list.length; i++) {
        if (list[i].match(regexp))
            result.push(list[i]);
    }
    return result;
}

proto.list_functions.unique = function(list) {
    var result = [];
    var seen = {};
    for (var i = 0; i < list.length; i++) {
        var elem = list[i];
        if (! seen[elem])
            result.push(elem);
        seen[elem] = true;
    }
    return result;
}

proto.list_functions.reverse = function(list) {
    var result = [];
    for (var i = list.length - 1; i >= 0; i--) {
        result.push(list[i]);
    }
    return result;
}

proto.list_functions.merge = function(list, args) {
    var result = [];
    var push_all = function(elem) {
        if (elem instanceof Array) {
            for (var j = 0; j < elem.length; j++) {
                result.push(elem[j]);
            }
        }
        else {
            result.push(elem);
        }
    }
    push_all(list);
    for (var i = 0; i < args.length; i++) {
        push_all(args[i]);
    }
    return result;
}

proto.list_functions.slice = function(list, args) {
    return list.slice(args[0], args[1]);
}

proto.list_functions.splice = function(list, args) {
    if (args.length == 1)
        return list.splice(args[0]);
    if (args.length == 2)
        return list.splice(args[0], args[1]);
    if (args.length == 3)
        return list.splice(args[0], args[1], args[2]);
}

proto.list_functions.push = function(list, args) {
    list.push(args[0]);
    return list;
}

proto.list_functions.pop = function(list) {
    return list.pop();
}

proto.list_functions.unshift = function(list, args) {
    list.unshift(args[0]);
    return list;
}

proto.list_functions.shift = function(list) {
    return list.shift();
}

proto.list_functions.first = function(list) {
    return list[0];
}

proto.list_functions.size = function(list) {
    return list.length;
}

proto.list_functions.max = function(list) {
    return list.length - 1;
}

proto.list_functions.last = function(list) {
    return list.slice(-1);
}

proto.hash_functions = {};


// each            list of alternating keys/values
proto.hash_functions.each = function(hash) {
    var list = new Array();
    for ( var key in hash )
        list.push(key, hash[key]);
    return list;
}

// exists(key)     does key exist?
proto.hash_functions.exists = function(hash, args) {
    return ( typeof( hash[args[0]] ) == "undefined" ) ? 0 : 1;
}

// FIXME proto.hash_functions.import blows everything up
//
// import(hash2)   import contents of hash2
// import          import into current namespace hash
//proto.hash_functions.import = function(hash, args) {
//    var hash2 = args[0];
//    for ( var key in hash2 )
//        hash[key] = hash2[key];
//    return '';
//}

// keys            list of keys
proto.hash_functions.keys = function(hash) {
    var list = new Array();
    for ( var key in hash )
        list.push(key);
    return list;
}

// list            returns alternating key, value
proto.hash_functions.list = function(hash, args) {
    var what = '';
    if ( args )
        var what = args[0];

    var list = new Array();
    if (what == 'keys')
        for ( var key in hash )
            list.push(key);
    else if (what == 'values')
        for ( var key in hash )
            list.push(hash[key]);
    else if (what == 'each')
        for ( var key in hash )
            list.push(key, hash[key]);
    else
        for ( var key in hash )
            list.push({ 'key': key, 'value': hash[key] });

    return list;
}

// nsort           keys sorted numerically
proto.hash_functions.nsort = function(hash) {
    var list = new Array();
    for (var key in hash)
        list.push(key);
    return list.sort(function(a, b) { return (a-b) });
}

// size            number of pairs
proto.hash_functions.size = function(hash) {
    var size = 0;
    for (var key in hash)
        size++;
    return size;
}


// sort            keys sorted alphabetically
proto.hash_functions.sort = function(hash) {
    var list = new Array();
    for (var key in hash)
        list.push(key);
    return list.sort();
}

// values          list of values
proto.hash_functions.values = function(hash) {
    var list = new Array();
    for ( var key in hash )
        list.push(hash[key]);
    return list;
}



//------------------------------------------------------------------------------
// Jemplate.Iterator class
//------------------------------------------------------------------------------
if (typeof Jemplate.Iterator == 'undefined') {
    Jemplate.Iterator = function(object) {
        if( object instanceof Array ) {
            this.object = object;
            this.size = object.length;
            this.max  = this.size -1;
        }
        else if ( object instanceof Object ) {
            this.object = object;
            var object_keys = new Array;
            for( var key in object ) {
                object_keys[object_keys.length] = key;
            }
            this.object_keys = object_keys.sort();
            this.size = object_keys.length;
            this.max  = this.size -1;
        }
    }
}

proto = Jemplate.Iterator.prototype;

proto.get_first = function() {
    this.index = 0;
    this.first = 1;
    this.last  = 0;
    this.count = 1;
    return this.get_next(1);
}

proto.get_next = function(should_init) {
    var object = this.object;
    var index;
    if( typeof(should_init) != 'undefined' && should_init ) {
        index = this.index;
    } else {
        index = ++this.index;
        this.first = 0;
        this.count = this.index + 1;
        if( this.index == this.size -1 ) {
            this.last = 1;
        }
    }
    if (typeof object == 'undefined')
        throw('No object to iterate');
    if( this.object_keys ) {
        if (index < this.object_keys.length) {
            this.prev = index > 0 ? this.object_keys[index - 1] : "";
            this.next = index < this.max ? this.object_keys[index + 1] : "";
            return [this.object_keys[index], false];
        }
    } else {
        if (index < object.length) {
            this.prev = index > 0 ? object[index - 1] : "";
            this.next = index < this.max ? object[index +1] : "";
            return [object[index], false];
        }
    }
    return [null, true];
}

//------------------------------------------------------------------------------
// Debugging Support
//------------------------------------------------------------------------------

function XXX(msg) {
    if (! confirm(msg))
        throw("terminated...");
    return msg;
}

function JJJ(obj) {
    return XXX(JSON.stringify(obj));
}

//------------------------------------------------------------------------------
// Ajax support
//------------------------------------------------------------------------------
if (! this.Ajax) Ajax = {};

Ajax.get = function(url, callback) {
    var req = new XMLHttpRequest();
    req.open('GET', url, Boolean(callback));
    return Ajax._send(req, null, callback);
}

Ajax.post = function(url, data, callback) {
    var req = new XMLHttpRequest();
    req.open('POST', url, Boolean(callback));
    req.setRequestHeader(
        'Content-Type',
        'application/x-www-form-urlencoded'
    );
    return Ajax._send(req, data, callback);
}

Ajax._send = function(req, data, callback) {
    if (callback) {
        req.onreadystatechange = function() {
            if (req.readyState == 4) {
                if(req.status == 200)
                    callback(req.responseText);
            }
        };
    }
    req.send(data);
    if (!callback) {
        if (req.status != 200)
            throw('Request for "' + url +
                  '" failed with status: ' + req.status);
        return req.responseText;
    }
}

//------------------------------------------------------------------------------
// Cross-Browser XMLHttpRequest v1.1
//------------------------------------------------------------------------------
/*
Emulate Gecko 'XMLHttpRequest()' functionality in IE and Opera. Opera requires
the Sun Java Runtime Environment <http://www.java.com/>.

by Andrew Gregory
http://www.scss.com.au/family/andrew/webdesign/xmlhttprequest/

This work is licensed under the Creative Commons Attribution License. To view a
copy of this license, visit http://creativecommons.org/licenses/by/1.0/ or send
a letter to Creative Commons, 559 Nathan Abbott Way, Stanford, California 94305,
USA.
*/

// IE support
if (window.ActiveXObject && !window.XMLHttpRequest) {
  window.XMLHttpRequest = function() {
    return new ActiveXObject((navigator.userAgent.toLowerCase().indexOf('msie 5') != -1) ? 'Microsoft.XMLHTTP' : 'Msxml2.XMLHTTP');
  };
}

// Opera support
if (window.opera && !window.XMLHttpRequest) {
  window.XMLHttpRequest = function() {
    this.readyState = 0; // 0=uninitialized,1=loading,2=loaded,3=interactive,4=complete
    this.status = 0; // HTTP status codes
    this.statusText = '';
    this._headers = [];
    this._aborted = false;
    this._async = true;
    this.abort = function() {
      this._aborted = true;
    };
    this.getAllResponseHeaders = function() {
      return this.getAllResponseHeader('*');
    };
    this.getAllResponseHeader = function(header) {
      var ret = '';
      for (var i = 0; i < this._headers.length; i++) {
        if (header == '*' || this._headers[i].h == header) {
          ret += this._headers[i].h + ': ' + this._headers[i].v + '\n';
        }
      }
      return ret;
    };
    this.setRequestHeader = function(header, value) {
      this._headers[this._headers.length] = {h:header, v:value};
    };
    this.open = function(method, url, async, user, password) {
      this.method = method;
      this.url = url;
      this._async = true;
      this._aborted = false;
      if (arguments.length >= 3) {
        this._async = async;
      }
      if (arguments.length > 3) {
        // user/password support requires a custom Authenticator class
        opera.postError('XMLHttpRequest.open() - user/password not supported');
      }
      this._headers = [];
      this.readyState = 1;
      if (this.onreadystatechange) {
        this.onreadystatechange();
      }
    };
    this.send = function(data) {
      if (!navigator.javaEnabled()) {
        alert("XMLHttpRequest.send() - Java must be installed and enabled.");
        return;
      }
      if (this._async) {
        setTimeout(this._sendasync, 0, this, data);
        // this is not really asynchronous and won't execute until the current
        // execution context ends
      } else {
        this._sendsync(data);
      }
    }
    this._sendasync = function(req, data) {
      if (!req._aborted) {
        req._sendsync(data);
      }
    };
    this._sendsync = function(data) {
      this.readyState = 2;
      if (this.onreadystatechange) {
        this.onreadystatechange();
      }
      // open connection
      var url = new java.net.URL(new java.net.URL(window.location.href), this.url);
      var conn = url.openConnection();
      for (var i = 0; i < this._headers.length; i++) {
        conn.setRequestProperty(this._headers[i].h, this._headers[i].v);
      }
      this._headers = [];
      if (this.method == 'POST') {
        // POST data
        conn.setDoOutput(true);
        var wr = new java.io.OutputStreamWriter(conn.getOutputStream());
        wr.write(data);
        wr.flush();
        wr.close();
      }
      // read response headers
      // NOTE: the getHeaderField() methods always return nulls for me :(
      var gotContentEncoding = false;
      var gotContentLength = false;
      var gotContentType = false;
      var gotDate = false;
      var gotExpiration = false;
      var gotLastModified = false;
      for (var i = 0; ; i++) {
        var hdrName = conn.getHeaderFieldKey(i);
        var hdrValue = conn.getHeaderField(i);
        if (hdrName == null && hdrValue == null) {
          break;
        }
        if (hdrName != null) {
          this._headers[this._headers.length] = {h:hdrName, v:hdrValue};
          switch (hdrName.toLowerCase()) {
            case 'content-encoding': gotContentEncoding = true; break;
            case 'content-length'  : gotContentLength   = true; break;
            case 'content-type'    : gotContentType     = true; break;
            case 'date'            : gotDate            = true; break;
            case 'expires'         : gotExpiration      = true; break;
            case 'last-modified'   : gotLastModified    = true; break;
          }
        }
      }
      // try to fill in any missing header information
      var val;
      val = conn.getContentEncoding();
      if (val != null && !gotContentEncoding) this._headers[this._headers.length] = {h:'Content-encoding', v:val};
      val = conn.getContentLength();
      if (val != -1 && !gotContentLength) this._headers[this._headers.length] = {h:'Content-length', v:val};
      val = conn.getContentType();
      if (val != null && !gotContentType) this._headers[this._headers.length] = {h:'Content-type', v:val};
      val = conn.getDate();
      if (val != 0 && !gotDate) this._headers[this._headers.length] = {h:'Date', v:(new Date(val)).toUTCString()};
      val = conn.getExpiration();
      if (val != 0 && !gotExpiration) this._headers[this._headers.length] = {h:'Expires', v:(new Date(val)).toUTCString()};
      val = conn.getLastModified();
      if (val != 0 && !gotLastModified) this._headers[this._headers.length] = {h:'Last-modified', v:(new Date(val)).toUTCString()};
      // read response data
      var reqdata = '';
      var stream = conn.getInputStream();
      if (stream) {
        var reader = new java.io.BufferedReader(new java.io.InputStreamReader(stream));
        var line;
        while ((line = reader.readLine()) != null) {
          if (this.readyState == 2) {
            this.readyState = 3;
            if (this.onreadystatechange) {
              this.onreadystatechange();
            }
          }
          reqdata += line + '\n';
        }
        reader.close();
        this.status = 200;
        this.statusText = 'OK';
        this.responseText = reqdata;
        this.readyState = 4;
        if (this.onreadystatechange) {
          this.onreadystatechange();
        }
        if (this.onload) {
          this.onload();
        }
      } else {
        // error
        this.status = 404;
        this.statusText = 'Not Found';
        this.responseText = '';
        this.readyState = 4;
        if (this.onreadystatechange) {
          this.onreadystatechange();
        }
        if (this.onerror) {
          this.onerror();
        }
      }
    };
  };
}
// ActiveXObject emulation
if (!window.ActiveXObject && window.XMLHttpRequest) {
  window.ActiveXObject = function(type) {
    switch (type.toLowerCase()) {
      case 'microsoft.xmlhttp':
      case 'msxml2.xmlhttp':
        return new XMLHttpRequest();
    }
    return null;
  };
}


//------------------------------------------------------------------------------
// JSON Support
//------------------------------------------------------------------------------

/*
Copyright (c) 2005 JSON.org
*/
var JSON = function () {
    var m = {
            '\b': '\\b',
            '\t': '\\t',
            '\n': '\\n',
            '\f': '\\f',
            '\r': '\\r',
            '"' : '\\"',
            '\\': '\\\\'
        },
        s = {
            'boolean': function (x) {
                return String(x);
            },
            number: function (x) {
                return isFinite(x) ? String(x) : 'null';
            },
            string: function (x) {
                if (/["\\\x00-\x1f]/.test(x)) {
                    x = x.replace(/([\x00-\x1f\\"])/g, function(a, b) {
                        var c = m[b];
                        if (c) {
                            return c;
                        }
                        c = b.charCodeAt();
                        return '\\u00' +
                            Math.floor(c / 16).toString(16) +
                            (c % 16).toString(16);
                    });
                }
                return '"' + x + '"';
            },
            object: function (x) {
                if (x) {
                    var a = [], b, f, i, l, v;
                    if (x instanceof Array) {
                        a[0] = '[';
                        l = x.length;
                        for (i = 0; i < l; i += 1) {
                            v = x[i];
                            f = s[typeof v];
                            if (f) {
                                v = f(v);
                                if (typeof v == 'string') {
                                    if (b) {
                                        a[a.length] = ',';
                                    }
                                    a[a.length] = v;
                                    b = true;
                                }
                            }
                        }
                        a[a.length] = ']';
                    } else if (x instanceof Object) {
                        a[0] = '{';
                        for (i in x) {
                            v = x[i];
                            f = s[typeof v];
                            if (f) {
                                v = f(v);
                                if (typeof v == 'string') {
                                    if (b) {
                                        a[a.length] = ',';
                                    }
                                    a.push(s.string(i), ':', v);
                                    b = true;
                                }
                            }
                        }
                        a[a.length] = '}';
                    } else {
                        return;
                    }
                    return a.join('');
                }
                return 'null';
            }
        };
    return {
        copyright: '(c)2005 JSON.org',
        license: 'http://www.crockford.com/JSON/license.html',
        stringify: function (v) {
            var f = s[typeof v];
            if (f) {
                v = f(v);
                if (typeof v == 'string') {
                    return v;
                }
            }
            return null;
        },
        parse: function (text) {
            try {
                return !(/[^,:{}\[\]0-9.\-+Eaeflnr-u \n\r\t]/.test(
                        text.replace(/"(\\.|[^"\\])*"/g, ''))) &&
                    eval('(' + text + ')');
            } catch (e) {
                return false;
            }
        }
    };
}();
...
}

#-------------------------------------------------------------------------------

sub new {
    my $class = shift;
    return bless { @_ }, $class;
}

sub compile_module {
    my ($self, $module_path, $template_file_paths) = @_;
    my $result = $self->compile_template_files(@$template_file_paths)
      or return;
    open MODULE, "> $module_path"
        or die "Can't open '$module_path' for output:\n$!";
    print MODULE $result;
    close MODULE;
    return 1;
}

sub compile_module_cached {
    my ($self, $module_path, $template_file_paths) = @_;
    my $m = -M $module_path;
    return 0 unless grep { -M($_) < $m } @$template_file_paths;
    return $self->compile_module($module_path, $template_file_paths);
}

sub compile_template_files {
    my $self = shift;
    my $output = $self->_preamble;
    for my $filepath (@_) {
        my $filename = $filepath;
        $filename =~ s/.*[\/\\]//;
        open FILE, $filepath
          or die "Can't open '$filepath' for input:\n$!";
        my $template_input = do {local $/; <FILE>};
        close FILE;
        $output .=
            $self->compile_template_content($template_input, $filename);
    }
    return $output;
}

sub compile_template_content {
    die "Invalid arguments in call to Jemplate->compile_template_content"
      unless @_ == 3;
    my ($self, $template_content, $template_name) = @_;
    my $parser = Jemplate::Parser->new( ref($self) ? %$self : () );
    my $parse_tree = $parser->parse(
        $template_content, {name => $template_name}
    ) or die $parser->error;
    my $output =
        "Jemplate.templateMap['$template_name'] = " .
        $parse_tree->{BLOCK} .
        "\n";
    for my $function_name (sort keys %{$parse_tree->{DEFBLOCKS}}) {
        $output .=
            "Jemplate.templateMap['$function_name'] = " .
            $parse_tree->{DEFBLOCKS}{$function_name} .
            "\n";
    }
    return $output;
}

sub _preamble {
    return <<'...';
/*
   This JavaScript code was generated by Jemplate, the JavaScript
   Template Toolkit. Any changes made to this file will be lost the next
   time the templates are compiled.

   Copyright 2006 - Ingy döt Net - All rights reserved.
*/

if (typeof(Jemplate) == 'undefined')
    throw('Jemplate.js must be loaded before any Jemplate template files');

...
}

1;

=head1 NAME

Jemplate - JavaScript Templating with Template Toolkit

=head1 SYNOPSIS

    var data = Ajax.get('url/data.json');
    var elem = document.getElementById('some-div');
    elem.innerHTML = Jemplate.process('my-template.html', data);

or:

    var data = Ajax.get('url/data.json');
    var elem = document.getElementById('some-div');
    Jemplate.process('my-template.html', data, elem);

or simply:

    Jemplate.process('my-template.html', 'url/data.json', '#some-div');

or, with Prototype.js:

    new Ajax.Request("url/data.json", {
        onComplete: function(req) {
            var data = eval(req.responseText);
            Jemplate.process('my-template.html', data, '#some-div');
        }
    );

=head1 DESCRIPTION

Jemplate is a templating framework for JavaScript that is built over
Perl's Template Toolkit (TT2).

Jemplate parses TT2 templates using the TT2 Perl framework, but with a
twist. Instead of compiling the templates into Perl code, it compiles
them into JavaScript.

Jemplate then provides a JavaScript runtime module for processing
the template code. Presto, we have full featured JavaScript
templating language!

Combined with JSON and xmlHttpRequest, Jemplate provides a really simple
and powerful way to do Ajax stuff.

=head1 HOWTO

Jemplate comes with a command line tool call C<jemplate> that you use to
precompile your templates into a JavaScript file. For example if you have
a template directory called C<templates> that contains:

    > ls templates/
    body.html
    footer.html
    header.html

You might run this command:

    > jemplate --compile template/* > js/jemplates.js

This will compile all the templates into one JavaScript file.

You also need to generate the Jemplate runtime.

    > jemplate --runtime > js/Jemplate.js

Now all you need to do is include these two files in the HEAD of
your html:

    <script src="js/Jemplate.js" type="text/javascript"></script>
    <script src="js/jemplates.js" type="text/javascript"></script>

Now you have Jemplate support for these templates in your html document.

=head1 PUBLIC API

The Jemplate.js JavaScript runtime module has the following API method:

=over

=item Jemplate.process(template-name, data, [target]);

The C<template-name> is a string like C<'body.html'> that is the name of
the top level template that you wish to process.

The C<data> can be a object, a function or a url. If it is an object, it
is used directly. If it is a function, the function is called and the
returned object is used. If it is a url, an asynchronous <Ajax.get> is
performed. The result is expected to be a JSON string, which gets turned
into an object.

The optional C<target> can be an HTMLElement reference, a function or a
string beginning with a C<#> char. If the target is omitted, the
template result is returned. If it is a function, the function is called
with the result. If it is a string, the string is used as an id to find
an HTMLElement.

If an HTMLElement is used (by id or directly) then the innerHTML
property is set to the template processing result.

=back

The Jemplate.pm Perl module has the following public class methods,
although you won't likely need to use them directly. Normally, you just
use the C<jemplate> command line tool.

=over

=item Jemplate->compile_template_files(@template_file_paths);

Take a list of template file paths and compile them into a module of
functions. Returns the text of the module.

=item Jemplate->compile_template_content($content, $template_name);

Compile one template whose content is in memory. You must provide a
unique template name. Returns the JavaScript text result of the
compilation.

=item Jemplate->compile_module($module_path, \@template_file_paths);

Similar to `compile_template_files`, but prints to result to the
$module_path. Returns 1 if successful, undef if error.

=item Jemplate->compile_module_cached($module_path, \@template_file_paths);

Similar to `compile_module`, but only compiles if one of the templates
is newer than the module. Returns 1 if sucessful compile, 0 if no
compile due to cache, undef if error.

=back

=head1 AJAX AND JSON METHODS

Jemplate comes with builtin Ajax and JSON support.

=over

=item Ajax.get(url, [callback]);

Does a GET operation to the url.

If a callback is provided, the operation is asynchronous, and the data
is passed to the callback. Otherwise, the operation is synchronous and
the data is returned.

=item Ajax.post(url, data, [callback]);

Does a POST operation to the url.

Same callback rules as C<get> apply.

=item JSON.stringify(object);

Return the JSON serialization of an object.

=item JSON.parse(jsonString);

Turns a JSON string into an object and returns the object.

=back

=head1 CURRENT SUPPORT

The goal of Jemplate is to support all of the Template Toolkit features
that can possibly be supported.

Jemplate now supports almost all the TT directives, including:

  * Plain text
  * [% [GET] variable %]
  * [% CALL variable %]
  * [% [SET] variable = value %]
  * [% DEFAULT variable = value ... %]
  * [% INCLUDE [arguments] %]
  * [% PROCESS [arguments] %]
  * [% BLOCK name %]
  * [% FILTER filter %] text... [% END %]
  * [% JAVASCRIPT %] code... [% END %]
  * [% WRAPPER template [variable = value ...] %]
  * [% IF condition %]
  * [% ELSIF condition %]
  * [% ELSE %]
  * [% SWITCH variable %]
  * [% CASE [{value|DEFAULT}] %]
  * [% FOR x = y %]
  * [% WHILE expression %]
  * [% RETURN %]
  * [% THROW type message %]
  * [% STOP %]
  * [% NEXT %]
  * [% LAST %]
  * [% CLEAR %]
  * [%# this is a comment %]

ALL of the string virtual functions are supported.

ALL of the array virtual functions are supported:

ALL of the hash virtual functions are supported (except for import):

MANY of the standard filters are implemented.

The remaining features will be added very soon. See the DESIGN document
in the distro for a list of all features and their progress.

=head1 BROWSER SUPPORT

Tested successfully in:

    * Firefox Mac/Win32/Linux
    * IE 6.0
    * Safari
    * Opera
    * Konqueror

All tests run 100% successful in the above browsers.

=head1 DEVELOPMENT

The bleeding edge code is available via Subversion at
http://svn.kwiki.org/ingy/Jemplate/

You can run the runtime tests directly from
http://svn.kwiki.org/ingy/Jemplate/tests/run/index.html or from the
corresponding CPAN or JSAN directories.

Jemplate development is being discussed at irc://irc.freenode.net/#jemplate

If you want a committer bit, just ask ingy on the irc channel.

=head1 CREDIT

This module is only possible because of Andy Wardley's mighty Template
Toolkit. Thanks Andy. I will gladly give you half of any beers I
receive for this work. (As long as you are in the same room when I'm
drinking them ;)

=head1 AUTHORS

Jemplate is truly a community authored project:

Ingy döt Net <ingy@cpan.org>

Tatsuhiko Miyagawa <miyagawa@bulknews.net>

Yann Kerherve <yannk@cpan.org>

David Davis <xantus@xantus.org>

Cory Bennett <coryb@corybennett.org>

Cees Hek <ceeshek@gmail.com>

Christian Hansen

David A. Coffey <dacoffey@cogsmith.com>

=head1 COPYRIGHT

Copyright (c) 2006. Ingy döt Net. All rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

See L<http://www.perl.com/perl/misc/Artistic.html>

=cut
