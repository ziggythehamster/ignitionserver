<!DOCTYPE style-sheet PUBLIC "-//James Clark//DTD DSSSL Style Sheet//EN" [
<!ENTITY docbook.dsl PUBLIC "-//Norman Walsh//DOCUMENT DocBook Print Stylesheet//EN" CDATA DSSSL>
]>

<style-sheet>
<style-specification use="docbook">
<style-specification-body>

;; $Header: /cvsroot/ignition/ignitionserver/docs/ignitionserver-docs.dsl,v 1.1 2005/07/04 19:39:01 ziggythehamster Exp $
;; This is for RTF files. They don't need a TOC

(define %generate-set-toc% #f)
(define %generate-book-toc% #f)
(define %generate-part-toc% #f)
(define %generate-reference-toc% #f)
(define %generate-article-toc% #f)

(define %generate-book-lot-list% '())

</style-specification-body>
</style-specification>

<external-specification id="docbook" document="docbook.dsl">

</style-sheet>
