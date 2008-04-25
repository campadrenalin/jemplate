if(typeof Jemplate=="undefined"){var Jemplate=function(){this.init.apply(this,arguments)}}Jemplate.process=function(){var A=new Jemplate();return A.process.apply(A,arguments)};(function(){if(!Jemplate.templateMap){Jemplate.templateMap={}}var B=Jemplate.prototype={};B.init=function(C){this.config=C||{AUTO_RESET:true,BLOCKS:{},CONTEXT:null,DEBUG_UNDEF:false,DEFAULT:null,ERROR:null,EVAL_JAVASCRIPT:false,FILTERS:{},INCLUDE_PATH:[""],INTERPOLATE:false,OUTPUT:null,PLUGINS:{},POST_PROCESS:[],PRE_PROCESS:[],PROCESS:null,RECURSION:false,STASH:null,TOLERANT:null,VARIABLES:{},WRAPPER:[]}};B.process=function(H,I,E){var G=this.config.CONTEXT||new Jemplate.Context();G.config=this.config;G.stash=this.config.STASH||new Jemplate.Stash();G.stash.__config__=this.config;G.__filter__=new Jemplate.Filter();G.__filter__.config=this.config;G.__plugin__=new Jemplate.Plugin();G.__plugin__.config=this.config;var C;var D=function(J){try{C=G.process(H,J)}catch(L){if(!String(L).match(/Jemplate\.STOP\n/)){throw (L)}C=L.toString().replace(/Jemplate\.STOP\n/,"")}if(typeof E=="undefined"){return C}if(typeof E=="function"){E(C);return null}if(typeof (E)=="string"||E instanceof String){if(E.match(/^#[\w\-]+$/)){var M=E.replace(/^#/,"");var K=document.getElementById(M);if(typeof K=="undefined"){throw ('No element found with id="'+M+'"')}K.innerHTML=C;return null}}else{E.innerHTML=C;return null}throw ("Invalid arguments in call to Jemplate.process");return 1};if(typeof I=="function"){I=I()}else{if(typeof I=="string"){var F=I;Jemplate.Ajax.processGet(F,function(J){D(J)});return null}}return D(I)};if(typeof Jemplate.Context=="undefined"){Jemplate.Context=function(){}}B=Jemplate.Context.prototype;B.include=function(D,C){return this.process(D,C,true)};B.process=function(E,D,G){if(G){this.stash.clone(D)}else{this.stash.update(D)}var F=Jemplate.templateMap[E];if(typeof F=="undefined"){throw ('No Jemplate template named "'+E+'" available')}var C=F(this);if(G){this.stash.declone()}return C};B.set_error=function(D,C){this._error=[D,C];return D};B.plugin=function(D,C){if(typeof D=="undefined"){throw"Unknown plugin name ':"+D+"'"}return new window[D](this,C)};B.filter=function(E,D,C){if(D=="null"){D="null_filter"}if(typeof this.__filter__.filters[D]=="function"){return this.__filter__.filters[D](E,C,this)}else{throw"Unknown filter name ':"+D+"'"}};if(typeof Jemplate.Plugin=="undefined"){Jemplate.Plugin=function(){}}B=Jemplate.Plugin.prototype;B.plugins={};if(typeof Jemplate.Filter=="undefined"){Jemplate.Filter=function(){}}B=Jemplate.Filter.prototype;B.filters={};B.filters.null_filter=function(C){return""};B.filters.upper=function(C){return C.toUpperCase()};B.filters.lower=function(C){return C.toLowerCase()};B.filters.ucfirst=function(E){var D=E.charAt(0);var C=E.substr(1);return D.toUpperCase()+C};B.filters.lcfirst=function(E){var D=E.charAt(0);var C=E.substr(1);return D.toLowerCase()+C};B.filters.trim=function(C){return C.replace(/^\s+/g,"").replace(/\s+$/g,"")};B.filters.collapse=function(C){return C.replace(/^\s+/g,"").replace(/\s+$/g,"").replace(/\s+/," ")};B.filters.html=function(C){C=C.replace(/&/g,"&amp;");C=C.replace(/</g,"&lt;");C=C.replace(/>/g,"&gt;");C=C.replace(/"/g,"&quot;");return C};B.filters.html_para=function(D){var C=D.split(/(?:\r?\n){2,}/);return"<p>\n"+C.join("\n</p>\n\n<p>\n")+"</p>\n"};B.filters.html_break=function(C){return C.replace(/(\r?\n){2,}/g,"$1<br />$1<br />$1")};B.filters.html_line_break=function(C){return C.replace(/(\r?\n)/g,"$1<br />$1")};B.filters.uri=function(C){return encodeURI(C)};B.filters.indent=function(H,D){var F=D[0];if(!H){return null}if(typeof F=="undefined"){F=4}var G="";if(typeof F=="number"||String(F).match(/^\d$/)){for(var E=0;E<F;E++){G+=" "}}else{G=F}var C=H.replace(/^/gm,G);return C};B.filters.truncate=function(F,D){var C=D[0];if(!F){return null}if(!C){C=32}if(F.length<C){return F}var E=C-3;return F.substr(0,E)+"..."};B.filters.repeat=function(F,C){if(!F){return null}if(!C||C==0){C=1}if(C==1){return F}var D=F;for(var E=1;E<C;E++){D+=F}return D};B.filters.replace=function(G,D){if(!G){return null}var C=D[0];var F=D[1];if(!C){C=""}if(!F){F=""}var E=new RegExp(C,"g");return G.replace(E,F)};if(typeof Jemplate.Stash=="undefined"){Jemplate.Stash=function(){this.data={}}}B=Jemplate.Stash.prototype;B.clone=function(C){var D=this.data;this.data={};this.update(D);this.update(C);this.data._PARENT=D};B.declone=function(C){this.data=this.data._PARENT||this.data};B.update=function(C){if(typeof C=="undefined"){return }for(var D in C){var E=C[D];this.set(D,E)}};B.get=function(F){var C=this.data;if(F instanceof Array){for(var E=0;E<F.length;E+=2){var D=F.slice(E,E+2);D.unshift(C);value=this._dotop.apply(this,D);if(typeof value=="undefined"){break}C=value}}else{value=this._dotop(C,F)}if(typeof value=="undefined"){if(this.__config__.DEBUG_UNDEF){throw ("undefined value found while using DEGUG_UNDEF")}value=""}return value};B.set=function(D,F,C){if(D instanceof Array){var E=this.get(D[0])||{};D=D[2]}else{E=this.data}if(!(C&&(typeof E[D]!="undefined"))){E[D]=F}};B._dotop=function(C,E,D){if(typeof E=="undefined"||typeof E=="string"&&E.match(/^[\._]/)){return undefined}if((!D)&&(typeof C=="object")&&(!(C instanceof Array)||(typeof E=="number"))&&(typeof C[E]!="undefined")){var F=C[E];if(typeof F=="function"){F=F.apply(C)}return F}if(typeof C=="string"&&this.string_functions[E]){return this.string_functions[E](C,D)}if(C instanceof Array&&this.list_functions[E]){return this.list_functions[E](C,D)}if(typeof C=="object"&&this.hash_functions[E]){return this.hash_functions[E](C,D)}if(typeof C[E]=="function"){return C[E].apply(C,D)}return undefined};B.string_functions={};B.string_functions.chunk=function(D,C){var E=C[0];var F=new Array();if(!E){E=1}if(E<0){E=0-E;for(i=D.length-E;i>=0;i=i-E){F.unshift(D.substr(i,E))}if(D.length%E){F.unshift(D.substr(0,D.length%E))}}else{for(i=0;i<D.length;i=i+E){F.push(D.substr(i,E))}}return F};B.string_functions.defined=function(C){return 1};B.string_functions.hash=function(C){return{"value":C}};B.string_functions.length=function(C){return C.length};B.string_functions.list=function(C){return[C]};B.string_functions.match=function(D,C){var F=new RegExp(C[0],"gm");var E=D.match(F);return E};B.string_functions.repeat=function(E,D){var G=D[0]||1;var C="";for(var F=0;F<G;F++){C+=E}return C};B.string_functions.replace=function(E,D){var G=new RegExp(D[0],"gm");var F=D[1];if(!F){F=""}var C=E.replace(G,F);return C};B.string_functions.search=function(D,C){var E=new RegExp(C[0]);return(D.search(E)>=0)?1:0};B.string_functions.size=function(C){return 1};B.string_functions.split=function(D,C){var F=new RegExp(C[0]);var E=D.split(F);return E};B.list_functions={};B.list_functions.join=function(D,C){return D.join(C[0])};B.list_functions.sort=function(D,C){if(typeof (C)!="undefined"&&C!=""){return D.sort(function(F,E){if(F[C]==E[C]){return 0}else{if(F[C]>E[C]){return 1}else{return -1}}})}return D.sort()};B.list_functions.nsort=function(C){return C.sort(function(E,D){return(E-D)})};B.list_functions.grep=function(G,D){var F=new RegExp(D[0]);var C=[];for(var E=0;E<G.length;E++){if(G[E].match(F)){C.push(G[E])}}return C};B.list_functions.unique=function(G){var C=[];var D={};for(var E=0;E<G.length;E++){var F=G[E];if(!D[F]){C.push(F)}D[F]=true}return C};B.list_functions.reverse=function(E){var C=[];for(var D=E.length-1;D>=0;D--){C.push(E[D])}return C};B.list_functions.merge=function(G,E){var C=[];var D=function(I){if(I instanceof Array){for(var H=0;H<I.length;H++){C.push(I[H])}}else{C.push(I)}};D(G);for(var F=0;F<E.length;F++){D(E[F])}return C};B.list_functions.slice=function(D,C){return D.slice(C[0],C[1])};B.list_functions.splice=function(D,C){if(C.length==1){return D.splice(C[0])}if(C.length==2){return D.splice(C[0],C[1])}if(C.length==3){return D.splice(C[0],C[1],C[2])}return null};B.list_functions.push=function(D,C){D.push(C[0]);return D};B.list_functions.pop=function(C){return C.pop()};B.list_functions.unshift=function(D,C){D.unshift(C[0]);return D};B.list_functions.shift=function(C){return C.shift()};B.list_functions.first=function(C){return C[0]};B.list_functions.size=function(C){return C.length};B.list_functions.max=function(C){return C.length-1};B.list_functions.last=function(C){return C.slice(-1)};B.hash_functions={};B.hash_functions.each=function(E){var D=new Array();for(var C in E){D.push(C,E[C])}return D};B.hash_functions.exists=function(D,C){return(typeof (D[C[0]])=="undefined")?0:1};B.hash_functions.keys=function(E){var D=new Array();for(var C in E){D.push(C)}return D};B.hash_functions.list=function(G,C){var F="";if(C){F=C[0]}var E=new Array();var D;if(F=="keys"){for(D in G){E.push(D)}}else{if(F=="values"){for(D in G){E.push(G[D])}}else{if(F=="each"){for(D in G){E.push(D,G[D])}}else{for(D in G){E.push({"key":D,"value":G[D]})}}}}return E};B.hash_functions.nsort=function(E){var D=new Array();for(var C in E){D.push(C)}return D.sort(function(G,F){return(G-F)})};B.hash_functions.size=function(E){var D=0;for(var C in E){D++}return D};B.hash_functions.sort=function(E){var D=new Array();for(var C in E){D.push(C)}return D.sort()};B.hash_functions.values=function(E){var D=new Array();for(var C in E){D.push(E[C])}return D};B.hash_functions.remove=function(D,C){return delete D[C[0]]};B.hash_functions["delete"]=B.hash_functions.remove;if(typeof Jemplate.Iterator=="undefined"){Jemplate.Iterator=function(D){if(D instanceof Array){this.object=D;this.size=D.length;this.max=this.size-1}else{if(D instanceof Object){this.object=D;var C=new Array;for(var E in D){C[C.length]=E}this.object_keys=C.sort();this.size=C.length;this.max=this.size-1}}}}B=Jemplate.Iterator.prototype;B.get_first=function(){this.index=0;this.first=1;this.last=0;this.count=1;return this.get_next(1)};B.get_next=function(C){var E=this.object;var D;if(typeof (C)!="undefined"&&C){D=this.index}else{D=++this.index;this.first=0;this.count=this.index+1;if(this.index==this.size-1){this.last=1}}if(typeof E=="undefined"){throw ("No object to iterate")}if(this.object_keys){if(D<this.object_keys.length){this.prev=D>0?this.object_keys[D-1]:"";this.next=D<this.max?this.object_keys[D+1]:"";return[this.object_keys[D],false]}}else{if(D<E.length){this.prev=D>0?E[D-1]:"";this.next=D<this.max?E[D+1]:"";return[E[D],false]}}return[null,true]};var A="stub that doesn't do anything. Try including the jQuery, YUI, or XHR option when building the runtime";Jemplate.Ajax={get:function(C,D){throw ("This is a Jemplate.Ajax.get "+A)},processGet:function(C,D){throw ("This is a Jemplate.Ajax.processGet "+A)},post:function(C,D){throw ("This is a Jemplate.Ajax.post "+A)}};Jemplate.JSON={parse:function(C){throw ("This is a Jemplate.JSON.parse "+A)},stringify:function(C){throw ("This is a Jemplate.JSON.stringify "+A)}}}())