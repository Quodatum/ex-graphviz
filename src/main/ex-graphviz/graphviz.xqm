(:~
: graphviz module
: based on http://www.zorba-xquery.com/html/modules/zorba/image/graphviz
:)

module namespace ex-graphviz="http://expkg-zone58.github.io/ex-graphviz";
declare default function namespace 'http://expkg-zone58.github.io/ex-graphviz';

import module namespace proc="http://basex.org/modules/proc";
import module namespace file="http://expath.org/ns/file";

declare namespace svg= "http://www.w3.org/2000/svg";
declare namespace  xlink="http://www.w3.org/1999/xlink";

declare %private variable $ex-graphviz:dotpath:=if(fn:environment-variable("DOTPATH"))
                                      then fn:environment-variable("DOTPATH")
                                      else "dot";
(:~
: folder for temp files \=windows
:)
declare %private variable $ex-graphviz:tmpdir:=if(file:dir-separator()="\")
                                      then fn:environment-variable("TEMP") || "\"
                                      else "/tmp/";
                                      
declare %private variable $ex-graphviz:empty:=document{
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 300 20" version="1.1" 
width="100%" height="100%" preserveAspectRatio="xMidYMid meet">
   <text x="150" y="10"  text-anchor="middle">Empty.</text>
</svg>
};


(:~
: Layout graphs given in the DOT language and 
: @return svg document
:)
declare function to-svg( $dot as xs:string) as document-node()
{
    to-svg( $dot, ()) 
};

(:~
:Layout one or more graphs given in the DOT language and render them as SVG.
:)
declare function to-svg( $dot as xs:string, $params as xs:string*) as document-node()
{
   let $params:=("-Tsvg")
   return if(fn:not($dot))
           then $ex-graphviz:empty
           else let $r:=dot-execute($dot,$params)
                return document{fn:parse-xml($r/output)}
};
(:~ run dot command :)
declare %private function dot-execute( $dot as xs:string, $params as xs:string*) as element(result)
{
    let $fname:=$ex-graphviz:tmpdir || random:uuid()
    let $junk:=file:write-text($fname,$dot)
    let $r:=proc:execute($ex-graphviz:dotpath , ($params,$fname))
    let $junk:=file:delete($fname)
    return if($r/code!="0")
           then  fn:error(xs:QName('ex-graphviz:dot1'),$r/error) 
           else $r
};

(:~ run dot command  returning binary :)
declare  function dot-executeb( $dot as xs:string, $params as xs:string*) as xs:base64Binary
{
    let $fname:=$ex-graphviz:tmpdir || random:uuid()
    let $oname:=$fname || ".o"
    let $junk:=file:write-text($fname,$dot)
    let $r:=proc:execute($ex-graphviz:dotpath , ($params,"-o"|| $oname,$fname))
    let $junk:=file:delete($fname)
    return if($r/code!="0")
           then  fn:error(xs:QName('ex-graphviz:dot1'),$r/error) 
           else  let $d:=file:read-binary($oname)
                 (: let $junk:=file:delete($oname) :) 
                 return $d                  
};

(:~ cleanup dot svg result :)
declare %private function dot-svg( $r as element(result)) as element(svg:svg)
{ 
    let $s:=fn:parse-xml($r/output)  (: o/p  has comment nodes :) 
    let $ver:=$s/comment()[1]/fn:normalize-space()
    let $title:=$s/comment()[2]/fn:normalize-space()
    let $svg:=$s/*
    return   <svg xmlns="http://www.w3.org/2000/svg" 
    xmlns:xlink="http://www.w3.org/1999/xlink" >
  {$svg/@* ,
  rdf($title,$ver),
  $svg/*}
  </svg>
 
};

declare function rdf($title as xs:string,
                    $ver as xs:string)
{
 <metadata>
    <rdf:RDF
           xmlns:rdf = "http://www.w3.org/1999/02/22-rdf-syntax-ns#"
           xmlns:rdfs = "http://www.w3.org/2000/01/rdf-schema#"
           xmlns:dc = "http://purl.org/dc/elements/1.1/" >
        <rdf:Description about="https://github.com/Quodatum/ex-graphviz"
             dc:title="{$title}"
             dc:description="A graph visualization"
             dc:date="{fn:current-dateTime()}"
             dc:format="image/svg+xml">
          <dc:creator>
            <rdf:Bag>
              <rdf:li>{$ver}</rdf:li>
              <rdf:li resource="https://github.com/Quodatum/ex-graphviz"/>
            </rdf:Bag>
          </dc:creator>
        </rdf:Description>
      </rdf:RDF>
      </metadata>
};

(:~
: set svg to autosize 100%
:)
declare function autosize($svg as element(svg:svg)) as element(svg:svg)
{
  <svg xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink"
  width="100%" height="100%" preserveAspectRatio="xMidYMid meet">
  {$svg/@* except ($svg/@width,$svg/@height,$svg/@preserveAspectRatio),
  $svg/*}
  </svg>
};
