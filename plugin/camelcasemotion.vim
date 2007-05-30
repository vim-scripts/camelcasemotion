" camelcasemotion.vim: Mappings for motion through CamelCaseWords and
" underscore_notation. 
"
" DESCRIPTION:
"   VIM provides many built-in motions, e.g. to move to the next word, or
"   end of the current word. Most programming languages use either CamelCase
"   ("anIdentifier") or underscore_notation ("an_identifier") naming
"   conventions for identifiers. The best way to navigate inside those
"   identifiers using VIM built-in motions is the '[count]f{char}' motion, i.e.
"   'f<uppercase char>' or 'f_', respectively. But we can make this easier: 
"
"   This script defines motions ',w', ',b' and ',e' (similar to 'w', 'b', 'e'),
"   which do not move word-wise (forward/backward), but Camel-wise; i.e. to word
"   boundaries and uppercase letters. The motions also work on underscore
"   notation, where words are delimited by underscore ('_') characters. 
"
" USAGE:
"   Use the new motions ',w', ',b' and ',e' in normal mode, operator-pending
"   mode (cp. :help operator), and visual mode. For example, type 'bc,w' to
"   change 'Camel' in 'CamelCase' to something else. 
"
" EXAMPLE:
"   Given the following CamelCase identifiers in a source code fragment:
"	set Script31337PathAndNameWithoutExtension11=%~dpn0
"	set Script31337PathANDNameWITHOUTExtension11=%~dpn0
"   and the corresponding identifiers in underscore_notation:
"	set script_31337_path_and_name_without_extension_11=%~dpn0
"	set SCRIPT_31337_PATH_AND_NAME_WITHOUT_EXTENSION_11=%~dpn0
"
"   ,w moves to ([x] is cursor position): [s]et, [s]cript, [3]1337, [p]ath,
"	[a]nd, [n]ame, [w]ithout, [e]xtension, [1]1, [d]pn0
"   ,b moves to: [d]pn0, [1]1, [e]xtension, [w]ithout, ...
"   ,e moves to: se[t], scrip[t], 3133[7], pat[h], an[d], nam[e], withou[t],
"	extensio[n], 1[1], dpn[0]
"
" INSTALLATION:
"   Put the script into your user or system VIM plugin directory (e.g.
"   ~/.vim/plugin). 
"
" DEPENDENCIES:
"   - Requires VIM 6.0 or higher for limited functionality
"     (,e motions do not work correctly and move like ,w).  
"   - Requires VIM 7.0 or higher for full functionality. 
"
" CONFIGURATION:
"
" LIMITATIONS:
"
" ASSUMPTIONS:
"
" KNOWN PROBLEMS:
"   - A degenerate CamelCaseWord containing '\U\u\d' (e.g. "MaP1Roblem")
"     confuses the operator-pending and visual mode ,e mapping. It'll skip "P"
"     and select "P1" in one step. As a workaround, use ',w' instead of ',e';
"     those two mappings have the same effect on CamelCaseWords, anyway. 
"   - The operator-pending and visual mode ,e mapping doesn't work properly when
"     it reaches the end of the buffer; the final character of the moved-over
"     "word" remains. As a workaround, use the default 'e' motion instead of
"     ',e'. 
"
" TODO:
"
" Copyright: (C) 2007 by Ingo Karkat
"   The VIM LICENSE applies to this script; see ':help copyright'. 
"
" Source: Based on vimtip #1016 by Anthony Van Ham. 
" Maintainer:	Ingo Karkat <ingo@karkat.de>
" REVISION	DATE		REMARKS 
"   1.10.009	28-May-2007	BF: The operator-pending and visual mode ,e
"				mapping doesn't work properly when it reaches
"				the end of line; the final character of the
"				moved-over "word" remains. Fixed this problem
"				unless the "word" is at the very end of the
"				buffer. 
"				BF: Degenerate CamelCaseWords that consist of
"				only a single uppercase letter (e.g. "P" in
"				"MapPRoblem") are skipped by all motions. Thanks
"				to Joseph Barker for reporting this. 
"				BF: In CamelCaseWords that consist of uppercase
"				letters followed by decimals (e.g.
"				"MyUPPER123Problem", the uppercase "word" is
"				skipped by all motions. 
"   1.10.008	28-May-2007	Incorporated major improvements and
"				simplifications done by Joseph Barker:
"				Operator-pending and visual mode motions now
"				accept [count] of more than 9. 
"				Visual selections can now be extended from
"				either end. 
"				Instead of misusing the :[range], the special
"				variable v:count1 is used. Custom commands are
"				not needed anymore. 
"				Operator-pending and visual mode mappings are
"				now generic: There's only a single mapping for
"				,w that can be repeated, rather than having a
"				separate mapping for 1,w 2,w 3,w ...
"   1.00.007	22-May-2007	Added documentation for publication. 
"	006	20-May-2007	BF: visual mode [1,2,3],e on pure CamelCase
"				mistakenly marks [2,4,6] words. If the cursor is
"				on a uppercase letter, the search pattern
"				'\u\l\+' doesn't match at the cursor position,
"				so another match won. Changed search pattern
"				from '\l\+', 
"	005	16-May-2007	Added support for underscore notation. 
"				Added support for "forward to end of word"
"				(',e') motion. 
"	004	16-May-2007	Improved search pattern so that
"				UppercaseWORDSInBetween and digits are handled,
"				too. 
"	003	15-May-2007	Changed mappings from <Leader>w to ,w; 
"				other \w mappings interfere here, because it's
"				irritating when the cursor jump doesn't happen
"				immediately, because VIM waits whether the
"				mapping is complete. ,w is faster to type that
"				\w (and, because of the left-right touch,
"				preferred over gw). 
"				Added visual mode mappings. 
"	0.02	15-Feb-2006	BF: missing <SID> for omaps. 
"	0.01	11-Oct-2005	file creation

" Avoid installing twice or when in compatible mode
if exists("loaded_camelcasemotion") || (v:version < 600)
    finish
endif
let loaded_camelcasemotion = 1

function! s:CamelCaseMotion( direction, count )
    "echo "count is " . a:count
    let l:i = 0
    while l:i < a:count
	if a:direction == 'e' || a:direction == 'E'
	    " "Forward to end" motion. 
	    "call search( '\>\|\(\a\|\d\)\+\ze_', 'We' )
	    call search( '\>\|\(\a\|\d\)\+\ze_\|\u\l\+\|\u\+\ze\(\u\l\|\d\)\|\d\+', 'We' )
	    if a:direction == 'E'
		" Note1: Special additional treatment for operator-pending mode
		" "forward to end" motion: 
		" The difference between normal mode, operator-pending and visual
		" mode is that in the latter two, the motion must go _past_ the
		" final "word" character, so that all characters of the "word" are
		" selected. This is done by appending a 'l' motion after the
		" search for the next "word". 
		"
		" In visual mode, the 'l' motion works fine at the end of
		" the line, and selects the last character of the line. Thus,
		" the 'l' motion is appended directly to the mapping. 

		" In operator-pending mode, the 'l' motion only works properly
		" at the end of the line (i.e. when the moved-over "word" is at
		" the end of the line) when the 'l' motion is allowed to move
		" over to the next line. Thus, the 'l' motion is added
		" temporarily to the global 'whichwrap' setting. 
		" Without this, the motion would leave out the last character in
		" the line. I've also experimented with temporarily setting
		" "set virtualedit=onemore" , but that didn't work. 
		let l:save_ww = &ww
		set ww+=l
		normal l
		let &ww = l:save_ww
	    endif
	else
	    " Forward (a:direction == '') and backward (a:direction == 'b')
	    " motion. 
	    "
	    " CamelCase: Jump to beginning of either (start of word, Word, WORD,
	    " 123). 
	    " Underscore notation: Jump to the beginning of an underscore-separated
	    " word or number. 
	    "call search( '\<\|\u', 'W' . a:direction )
	    "call search( '\<\|\u\(\l\+\|\u\+\ze\u\)\|\d\+', 'W' . a:direction )
	    "call search( '\<\|\u\(\l\+\|\u\+\ze\u\)\|\d\+\|_\zs\(\a\|\d\)\+', 'W' . a:direction )
	    call search( '\<\(\u\+\ze\u\)\?\|_\zs\(\a\|\d\)\+\|\u\l\+\|\u\+\ze\(\u\l\|\d\)\|\d\+', 'W' . a:direction )
	endif
	let l:i = l:i + 1
    endwhile
endfunction

"------------------------------------------------------------------------------
" The count is passed into the function through the special variable 'v:count1',
" which is easier than misusing the :[range] that :call supports. 
" <C-U> is used to delete the unused range. 
" Another option would be to use a custom 'command! -count=1', but that doesn't
" work with the normal mode mapping: When a count is typed before the mapping,
" the ':' will convert a count of 3 into ':.,+2MyCommand', but ':3MyCommand'
" would be required to use -count and <count>. 

" Normal mode motions:
nmap <silent> ,w :<C-U>call <SID>CamelCaseMotion( 'w', v:count1 )<CR>
nmap <silent> ,b :<C-U>call <SID>CamelCaseMotion( 'b', v:count1 )<CR>
nmap <silent> ,e :<C-U>call <SID>CamelCaseMotion( 'e', v:count1 )<CR>
" We do not provide the fourth "backward to end" motion (,E), because it is
" seldomly used. 


" Operator-pending mode motions:
omap <silent> ,w :<C-U>call <SID>CamelCaseMotion( 'w', v:count1 )<CR>
omap <silent> ,b :<C-U>call <SID>CamelCaseMotion( 'b', v:count1 )<CR>
omap <silent> ,e :<C-U>call <SID>CamelCaseMotion( 'E', v:count1 )<CR>
" Note: Special argument 'E' for ,e motion. See Note1. 


" Visual mode motions:
" The expression is used to translate the optional [count] into multiple
" invocations of the <SID>CamelCaseMotion(..., 1) function. 
" The octal string constant \33 corresponds to <Esc>, and is used to exit the
" expression; ':' then enters command mode, and the second octal string constant
" \25 corresponds to <C-U>, which is used to clear the unused visual range
" (:`<,`>). 
" Finally, the current cursor position is stored in the ` mark, the visual
" selection is restored ('gv'), and the cursor position is restored ('g``').
" This allows the visual selection to be extended from either end, i.e. you can
" first use 'bv3,w' on "CamelCaseWordExample" to select "CamelCaseWord", then
" use ',b' to shink the selection to "CamelCase". 
vmap <silent> ,w @="\33:\25call <SID>CamelCaseMotion( 'w', 1 )"<CR><CR>m`gvg``
vmap <silent> ,b @="\33:\25call <SID>CamelCaseMotion( 'b', 1 )"<CR><CR>m`gvg``
vmap <silent> ,e @="\33:\25call <SID>CamelCaseMotion( 'e', 1 )"<CR><CR>m`gvg``l
" Note: The mapping for motion ,e appends an additional 'l' motion. See Note1. 

" vim: set sts=4 sw=4 noexpandtab ff=unix fdm=syntax :
