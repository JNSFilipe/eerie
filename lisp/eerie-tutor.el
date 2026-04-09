;;; eerie-tutor.el --- Tutor for Eerie  -*- lexical-binding: t; -*-

;; This file is not part of GNU Emacs.

;; This program is free software; you can redistribute it and/or
;; modify it under the terms of the GNU General Public License
;; as published by the Free Software Foundation; either version 3
;; of the License, or (at your option) any later version.

;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with GNU Emacs; see the file COPYING.  If not, write to the
;; Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor,
;; Boston, MA 02110-1301, USA.

;;; Commentary:
;; A tutorial for Eerie.
;;
;; To start, with M-x eerie-tutor

;;; Code:

(require 'eerie-var)

(defconst eerie--tutor-content
  "
             ███╗░░░███╗███████╗░█████╗░░██╗░░░░░░░██╗
             ████╗░████║██╔════╝██╔══██╗░██║░░██╗░░██║
             ██╔████╔██║█████╗░░██║░░██║░╚██╗████╗██╔╝
             ██║╚██╔╝██║██╔══╝░░██║░░██║░░████╔═████║░
             ██║░╚═╝░██║███████╗╚█████╔╝░░╚██╔╝░╚██╔╝░
             ╚═╝░░░░░╚═╝╚══════╝░╚════╝░░░░╚═╝░░░╚═╝░░

==================================================================
=                      MEOW INTRODUCTION                         =
==================================================================

 Eerie is yet another modal editing mode for Emacs.
 What's modal editing? How do I use Eerie? Let's start our journey!

 If you wonder what a keystroke means when reading this, just ask
 Emacs! Press C-h k then press the key you want to query.

==================================================================
=                     BASIC CURSOR MOVEMENT                      =
==================================================================

  To move up, press \\[eerie-prev]
  To move down, press \\[eerie-next]
  To move left, press \\[eerie-left]
  To move right, press \\[eerie-right]
       ↑
       \\[eerie-prev]
   ← \\[eerie-left]   \\[eerie-right] →
       \\[eerie-next]
       ↓

 You can move the cursor using the \\[eerie-left], \\[eerie-next], \\[eerie-prev], \\[eerie-right] keys, as shown
 above. Arrow keys also work, but it is faster to use the \\[eerie-left]\\[eerie-next]\\[eerie-prev]\\[eerie-right]
 keys as they are closer to the other keys you will be using.
 Try moving around to get a feel for \\[eerie-left]\\[eerie-next]\\[eerie-prev]\\[eerie-right].
 Once you're ready, hold \\[eerie-next] to continue to the next lesson.

 Eerie provides modal editing which means you have different
 modes for inserting and editing text. The primary modes you will
 use are Normal mode and Insert mode. While in Normal mode, the
 keys you press won't actually type text. Instead, they will
 perform various actions with the text. This allows for more
 efficient editing. This tutor will teach you how you can make
 use of Eerie's modal editing features. To begin, ensure your
 caps-lock key is not pressed and hold the \\[eerie-next] key until you reach
 the first lesson.

=================================================================
=                           DELETION                            =
=================================================================

 Pressing the \\[eerie-delete] key deletes the character under the cursor.
 \\[eerie-backward-delete] key deletes the character before the cursor (backspace).

 1. Move the cursor to the line below marked -->.
 2. Move the cursor to each extra character, and press \\[eerie-delete] to
    delete it.

 --> Thhiss senttencee haass exxtra charracterss.
     This sentence has extra characters.

 Once both sentences are identical, move to the next lesson.

=================================================================
=                          INSERT MODE                          =
=================================================================

 Pressing the \\[eerie-insert] key enters the Insert mode. In that mode you can
 enter text. <ESC> returns you back to Normal mode. The modeline
 will display your current mode. When you press \\[eerie-insert], '%s'
 changes to '%s'.

 1. Move the cursor to the line below marked -->.
 2. Insert the missing characters with \\[eerie-insert] key.
 3. Press <ESC> to return back to Normal mode.
 4. Repeat until the line matches the line below it.

 --> Th stce misg so.
     This sentence is missing some text.

 Note: If you want to move the cursor while in Insert mode, you
       can use the arrow keys instead of exiting and re-entering
       Insert mode.

=================================================================
=                      MORE ON INSERT MODE                      =
=================================================================

 Pressing \\[eerie-insert] is not the only way to enter Insert Mode. Here are
 some other ways to enter Insert mode at different locations.

 Common examples of insertion commands include:

   \\[eerie-insert]   - Insert cursor before the selection.
   \\[eerie-append]   - Insert cursor after the selection.
   \\[eerie-join] \\[eerie-append] - Insert cursor at the start of the line.
   \\[eerie-line] \\[eerie-append] - Insert cursor at the end of the line.

 These commands are composable. \\[eerie-join] will select the beginning of the
 current line up until the end of the non-empty line above.
 \\[eerie-append] switches to Insert mode at the end of current selection.
 Using both commands together will result in the cursor position being at
 the beginning of the line (Insert mode). \\[eerie-line] selects the whole
 line and enables the use of the same insertion commands.

 1. Move to anywhere in the line below marked -->.
 2. Press \\[eerie-line] \\[eerie-append], your cursor will move to the end of the line
    and you will be able to type.
 3. Type the necessary text to match the line below.
 4. Press \\[eerie-join] \\[eerie-append] for the cursor to move to the beginning of the line.
    This will place the cursor before -->. For now just return to
    Normal mode and move cursor past it.

 -->  sentence is miss
     This sentence is missing some text.

=================================================================
=                             RECAP                             =
=================================================================

 + Use the \\[eerie-left], \\[eerie-next], \\[eerie-prev], \\[eerie-right] keys to move the cursor.

 + Press \\[eerie-delete] to delete the character under the cursor.

 + Press \\[eerie-backward-delete] to delete the character before the cursor.

 + Press \\[eerie-insert] to enter Insert mode to input text. Press <ESC> to
   return to Normal mode.

 + Press \\[eerie-join] to select the start of the current line and
   the non-empty line above.

 + Press \\[eerie-append] to enter Insert mode, with the cursor position being
   at the end of the selected region.

=================================================================
=                    MOTIONS AND SELECTIONS                     =
=================================================================

 Pressing \\[eerie-next-word] will select everything from the cursor position
 until the end of the current word.
 Numbers that show up on the screen indicate a quick way to extend your selection.
 You can unselect the region with the \\[eerie-cancel-selection] key.

 Pressing \\[eerie-kill] will delete the current selection.

 The \\[eerie-delete] key deletes the character below the cursor, while
 \\[eerie-kill] deletes all of the selected text.

 1. Move the cursor to the line below marked -->.
 2. Move to the beginning of a word that needs to be deleted.
 3. Press \\[eerie-next-word] to select a word.
 4. Press \\[eerie-kill] to delete the selection.
 5. Repeat for all extra words in the line.

 --> This sentence pencil has vacuum extra words in the it.
     This sentence has vacuum words in it.

 Note: Pressing \\[eerie-kill] without a selection will delete everything
       from cursor position until the end of line.

=================================================================
=                       WORDS VS SYMBOLS                        =
=================================================================

 Pressing \\[eerie-mark-word] will select the whole word under the cursor. \\[eerie-mark-symbol] will
 select the whole symbol. Symbols are separated only by whitespace,
 whereas words can also be separated by other characters.

 To understand the difference better, do the following exercise:

 1. Move the cursor to the line below marked -->.
 2. Use \\[eerie-mark-word] and \\[eerie-mark-symbol] on each word in a sentence.
 3. Observe the difference in selection.

 --> Select-this and this.

=================================================================
=                    EXTENDING SELECTION                        =
=================================================================

 Motions are useful for extending the current selection and for
 quick movement around the text.

   \\[eerie-next-word] - Moves forward to the end of the current word.
   \\[eerie-back-word] - Moves backward to the beginning of the current word.
   \\[eerie-next-symbol] - Moves to the end of the current symbol.
   \\[eerie-back-symbol] - Moves to the start of the current symbol.

 After selecting the word under the cursor with \\[eerie-mark-word] you can
 extend the selection using the same commands.

   \\[eerie-next-word] - Adds the next word to the selection.
   \\[eerie-back-word] - Adds the previous word to the selection.
   \\[eerie-next-symbol] - Adds the next symbol to the selection.
   \\[eerie-back-symbol] - Adds the previous symbol to the selection.

 In-case too much gets selected, you can undo the previous selection
 with \\[eerie-pop-selection] key.

 1. Move the cursor to the line below marked -->.
 2. Select the word with \\[eerie-mark-word].
 3. Extend the selection with \\[eerie-next-word].
 4. Press \\[eerie-kill] to delete the selection.

 --> This sentence is most definitelly not at all short.
     This sentence is short.

=================================================================
=                        SELECTING LINES                        =
=================================================================

 Pressing \\[eerie-line] will select the whole line. Pressing it again will
 add the next line to the selection. Numbers can also be used
 to select multiple lines at once. Cursor position can be reversed with
 \\[eerie-reverse] to extend the selection in the other direction.

 1. Move the cursor to the second line below marked -->.
 2. Press \\[eerie-line] to select the current line, and \\[eerie-kill] to delete it.
 3. Move to the fourth line.
 4. Select 2 lines either by hitting \\[eerie-line] twice or \\[eerie-line] 1 in combination.
 5. Delete the selection with \\[eerie-kill].
 6. (Optional) Try reversing the cursor and extending the selection.

 --> 1) Roses are red,
 --> 2) Mud is fun,
 --> 3) Violets are blue,
 --> 4) I have a car,
 --> 5) Clocks tell time,
 --> 6) Sugar is sweet,
 --> 7) And so are you.

=================================================================
=                 EXTENDING SELECTION BY OBJECT                 =
=================================================================

 Expanding the selected region is easy. In fact every motion
 command has its own expand type. Motions can be expanded in
 different directions and units.

 Common selection expanding motions by a THING:

   \\[eerie-beginning-of-thing] - expand before cursor until beginning of...
   \\[eerie-end-of-thing] - expand after cursor until end of...
   \\[eerie-inner-of-thing] - select the inner part of...
   \\[eerie-bounds-of-thing] - select the whole part of...

 Some of THING modifiers may include:

  r - round parenthesis
  s - square parenthesis
  c - curly parenthesis
  g - string
  p - paragraph
  l - line
  d - defun
  b - buffer

 1. Move the cursor to the paragraph below.
 2. Type \\[eerie-bounds-of-thing] p to select the whole paragraph.
 3. Type \\[eerie-cancel-selection] to cancel the selection.
 4. Type \\[eerie-inner-of-thing] l to select one line.
 5. Type \\[eerie-cancel-selection] to cancel the selection.
 6. Play with the commands you learned this section. You can do anything
    you want with these powerful commands!

 War and Peace by Leo Tolstoy, is considered one of the greatest works of
 fiction.It is regarded, along with Anna Karenina (1873–1877), as Tolstoy's
 finest literary achievement. Epic in scale, War and Peace delineates in graphic
 detail events leading up to Napoleon's invasion of Russia, and the impact of the
 Napoleonic era on Tsarist society, as seen through the eyes of five Russian
 aristocratic families.Newsweek in 2009 ranked it top of its list of Top 100
 Books.Tolstoy himself, somewhat enigmatically, said of War and Peace that it was
 \"not a novel, even less is it a poem, and still less an historical chronicle.\"

=================================================================
=                      MOVE AROUND THINGs                       =
=================================================================

 You can also move around things. In fact, Eerie combines move and
 selection together. Every time you select something, the cursor
 will move to the beginning/end/inner/bound of things depending
 on your commands. Let's practice!

 * How to jump to the beginning of buffer quickly?

   Type \\[eerie-beginning-of-thing] and \"b\". Remember to come
   back by typing \\[eerie-pop-selection].

 * How to jump to the end of buffer quickly?

   I believe you could figure it out. Do it!

 * How to jump to the end of the current function quickly?

   1. Move cursor to the function below marked -->.
   2. Type \\[eerie-bounds-of-thing] and \"c\", then \\[eerie-append].
  
   -->
   fn count_ones(mut n: i64) -> usize {
    let mut count: usize = 0;
    while 0 < n {
        count += (1 & n) as usize;
        n >>= 1;
    }
    count
   }

 Note that Eerie needs the major mode for the programming language
 to find functions correctly. Then if you type \\[eerie-bounds-of-thing] and \"d\" to
 select the whole function here, it won't work. Go to your
 favorite programming language mode and practice!

=================================================================
=                   THE FIND/TILL COMMAND                       =
=================================================================

 Type \\[eerie-till] to select until the next specific character.

 1. Move the cursor to the line below marked -->.
 2. Press \\[eerie-till]. A prompt will appear in minibuffer.
 4. Type 'a'. The correct position for the next 'a' will be
    selected.

 --> I like to eat apples since my favorite fruit is apples.

 Note: If you want to go backwards, use \\[negative-argument] as a prefix; there is also
       a similar command on \\[eerie-find], which will jump over that
       character.

=================================================================
=                            RECAP                              =
=================================================================

 + Unselect region with \\[eerie-cancel-selection] key.

 + Reverse cursor position in selected region with \\[eerie-reverse] key.

 + Undo selection with \\[eerie-pop-selection].

 + Press \\[eerie-next-word] to select until the end of current word.

 + Press \\[eerie-back-word] to select until the start of closest word.

 + Press \\[eerie-next-symbol] to select until the end of symbol.

 + Press \\[eerie-back-symbol] to select until the start of symbol.

 + Press \\[eerie-line] to select the entire current line. Type \\[eerie-line] again to
   select the next line.

 + Motion can be repeated multiple times by using a number modifier.

 + Extend selection by using THING modifiers
   Motion Prefix: (\\[eerie-beginning-of-thing] \\[eerie-end-of-thing] \\[eerie-inner-of-thing] \\[eerie-bounds-of-thing])
   THING as a Suffix: (r,s,c,g,p,l,d,b)

 + Find by a single character with \\[eerie-till] and \\[eerie-find].

=================================================================
=                      THE CHANGE COMMAND                       =
=================================================================

 Pressing \\[eerie-change] will delete the current selection and switch to
 Insert mode. If there is no selection it will only delete
 the character under the cursor and switch to Insert mode.
 It is a shorthand for \\[eerie-delete] \\[eerie-insert].

 1. Move the cursor to the line below marked -->.
 2. Select the incorrect word with \\[eerie-next-word].
 3. Press \\[eerie-change] to delete the word and enter Insert mode.
 4. Replace it with correct word and return to Normal mode.
 5. Repeat until the line matches the line below it.

 --> This paper has heavy words behind it.
     This sentence has incorrect words in it.

=================================================================
=                         KILL AND YANK                         =
=================================================================

 The \\[eerie-kill] key also copies the deleted content which can then be
 pasted with \\[eerie-yank].

 1. Move the cursor to the line below marked -->.
 2. Type \\[eerie-line] to select the line.
 3. Type \\[eerie-kill] to cut the current selection.
 4. Type \\[eerie-yank] to paste the copied content.
 5. You can paste as many times as you want.

 --> Violets are blue, and I love you.

=================================================================
=                         SAVE AND YANK                         =
=================================================================

 Pressing \\[eerie-save] copies the selection, which can then be pasted
 with \\[eerie-yank] under the cursor.

 1. Move the cursor to the line below marked -->.
 2. Press \\[eerie-line] to select one line forward.
 3. Press \\[eerie-save] to copy the current selection.
 4. Press \\[eerie-yank] to paste the copied content.
 5. You can paste as many times as you want.

 --> Violets are blue, and I love you.

=================================================================
=                            UNDOING                            =
=================================================================

 Pressing \\[eerie-undo] triggers undo. The \\[eerie-undo-in-selection] key will only undo the changes
 in the selected region.

 1. Move the cursor to the line below marked -->.
 2. Move to the first error, and press \\[eerie-delete] to delete it.
 3. Type \\[eerie-undo] to undo your deletion.
 4. Fix all the errors on the line.
 5. Type \\[eerie-undo] several times to undo your fixes.

 --> Fiix the errors on thhis line and reeplace them witth undo.
     Fix the errors on this line and replace them with undo.

=================================================================
=                             RECAP                             =
=================================================================

 + Press \\[eerie-change] to delete the selection and enter Insert mode.

 + Press \\[eerie-save] to copy the selection.

 + Press \\[eerie-yank] to paste the copied or deleted text.

 + Press \\[eerie-undo] to undo last change.

 + Press \\[eerie-undo-in-selection] to only undo changes in the selected region.

=================================================================
=               BEACON (BATCHED KEYBOARD MACROS)                =
=================================================================

 Keyboard macro is a function that is built-in to Emacs. Now with Eerie, it's
 more powerful. We can do things like multi-editing with Beacon
 mode in Eerie.

 Select a region, then press \\[eerie-grab] to \"grab\" it, then enter
 Insert mode, eerie will now enter Beacon mode. Eerie will create multiple
 cursors and all edits you do to one cursor will be synced to other
 cursors after you exit Insert mode. Type \\[eerie-grab] again to cancel
 grabbing.

 1. Move the cursor to the first line below marked -->.
 2. Select the six lines.
 3. Type \\[eerie-grab] to grab the selection. Edits you
    make will be synced to the other cursors.
 4. Use Insert mode to correct the lines. Then exit Insert mode.
    Other cursors will fix the other lines after you exit Insert mode.
 5. Type \\[eerie-grab] to cancel the grabbing.

 --> Fix th six nes at same ime.
 --> Fix th six nes at same ime.
 --> Fix th six nes at same ime.
 --> Fix th six nes at same ime.
 --> Fix th six nes at same ime.
 --> Fix th six nes at same ime.
     Fix these six lines at the same time.

=================================================================
=                         MORE ON BEACON                        =
=================================================================

 BEACON is powerful! Let's do some more practice.

 Ex. A. How to achieve this?
        1 2 3
        =>
        [| \"1\" |] [| \"2\" |] [| \"3\" |]

 1. Move the cursor to the line below marked -->
 2. Select the \"1 2 3\"
 3. Press \\[eerie-grab] to grab the selection
 4. Press \\[eerie-back-word] to create fake cursors at the beginning of each word
    in the backwards direction.
 5. Enter Insert Mode then edit.
 6. Press \\[eerie-normal-mode] to stop macro recording and apply
    your edits to all fake cursors.
 7. Press \\[eerie-grab] to cancel grab.
 --> 1 2 3
     [| \"1\" |] [| \"2\" |] [| \"3\" |]

 Ex. B. How to achieve this?
        x-y-foo-bar-baz
        =>
        x_y_foo_bar_baz

 1. Move the cursor to the line below marked -->
 2. Select the whole symbol with \\[eerie-mark-symbol]
 3. Press \\[eerie-grab] to activate secondary selection
 4. Press \\[negative-argument] \\[eerie-find] and - to backward search for
    character -, will create fake cursor at each -
 5. Eerie will start recording. Press \\[eerie-change] to switch to Insert mode
    (character under current cursor is deleted)
 6. type _
 7. Press ESC to go back to NORMAL, then the macro will
    be applied to all fake cursors.
 8. Press \\[eerie-grab] again to cancel the grab

 --> x-y-foo-bar-baz
     x_y_foo_bar_baz

=================================================================
=                     QUICK VISIT AND SEARCH                    =
=================================================================

 The visit command \\[eerie-visit] can help to select a symbol in your
 buffer with completion. Once you have something selected with the \\[eerie-visit] key,
 you can use \\[eerie-search] to search for the next occurrence of that selection.

 If you want a backward search, you can reverse the selection with \\[eerie-reverse]
 because \\[eerie-search] will respect the direction of the current selection.

 1. Move the cursor to the line below marked -->.
 2. Select the word \"dog\" with \\[eerie-visit] dog RET.
 3. Change it to \"cat\" with \\[eerie-change] cat ESC.
 4. Save it with \\[eerie-save].
 5. Search for next \"dog\" and replace it with \\[eerie-search] \\[eerie-replace].
 6. Repeat 5 to replace next \"dog\".

 --> I'm going to tell you something:
     dog is beautiful
     and dog is agile
     the last one, dog says eerie

 Note: You can also start searching after \\[eerie-mark-word] or \\[eerie-mark-symbol]. Actually, you
       can use \\[eerie-search] whenever you have any kind of selection. The search command
       is built on regular expression. The symbol boundary will be
       added to your search if the selection is created with \\[eerie-visit], \\[eerie-mark-word] and \\[eerie-mark-symbol].

=================================================================
=                    KEYPAD                                     =
=================================================================

 One of the most notable features of Eerie is the Keypad. It
 enables the use of modifier keybinds without pressing modifiers.

 To enter Keypad mode, press SPC in Normal mode or Motion mode.

 Once Keypad is started, your single key input, will be translated
 based on following rules:

 1. The first letter input, except x, c, h, m, g will be
 translated to C-c <key>.

 Example: a => C-c a

 Press SPC a, call the command on C-c a, which is
 undefined by default.

 2. m will be translated to M-, means next input should be
 modified with Meta.

 Example: m h => M-h

 Press SPC m h, call the command on M-h, which is
 mark-paragraph by default.

 3. Several keys are bound to prefixes similarly. Specifically,
 x -> C-x
 h -> C-h
 c -> C-c
 m -> M-
 g -> C-M-

 4. Any key following a prefix is interpreted as C-<key>.

 Example: x f => C-x C-f

 Press SPC x f, call the command on C-x C-f, which is
 find-file by default.

 5. Use SPC to indicate a literal key, which will not be modified with C-

 Example: m g SPC g => M-g g

 Press SPC m g SPC g, call the command on M-g g, which is
 goto-line by default.

 Sometimes, you can omit this SPC when there's no ambiguity.

 6. After one execution, regardless of success or failure, Keypad will
 quit automatically, and the previous mode will be enabled.

 7. To undo one input, press BACKSPACE. To cancel and exit Keypad
 immediately, press ESC or C-g.

=================================================================
=                     MEOW CHEAT SHEET                          =
=================================================================

 All these keybinds are shown on the cheat sheet which can be
 opened by pressing \\[eerie-cheatsheet].

=================================================================
")

(defun eerie-tutor ()
  "Open a buffer with eerie tutor."
  (interactive)
  (let ((buf (get-buffer-create "*Eerie Tutor*")))
    (with-current-buffer buf
      (erase-buffer)
      (insert (format (substitute-command-keys eerie--tutor-content)
                      (alist-get 'normal eerie-replace-state-name-list)
                      (alist-get 'insert eerie-replace-state-name-list)))
      (goto-char (point-min))
      (display-line-numbers-mode))
    (switch-to-buffer buf)))

(provide 'eerie-tutor)
;;; eerie-tutor.el ends here
