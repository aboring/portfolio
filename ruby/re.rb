def phone_re
   /^(\d{3}-\d{4}|\d{3}-\d{3}-\d{4}|\(\d{3}\) \d{3}-\d{4})$/
end

def sentence_re

   first = /[A-Z][A-Za-z]*/
   words = / [A-Za-z]+/
   punc  = /\?!|!\?|[\!\?]|\./

   /^(#{first})(#{words}*)(#{punc})$/
end

def hours_re
   day = /[MTWHF]/
   days = /#{day}(-#{day}|#{day}+)?/
   hour = /[012]?\d:[0-5][05]/
   hours = /#{hour}-#{hour}/
   both = /#{days} #{hours}/

   /^#{both}(, #{both})*$/   
end

def perms_re
   perm = /[-r][-w][-x]/
   other = /r--|-w-|--x|rw-|r-x|-wx|rwx/
   lows = /[a-z]+/
   month = /Jan|Feb|Mar|Apr|May|Jun|Jul|Aug|Sep|Oct|Nov|Dec/
   yt = /\d{4}|[012]?\d:[0-5][0-9]/
 
   word = /[A-Za-z\-\.0-9_\/]/
   filename = /((\.)?\/)?#{word}+#{word}*/

   /^[-d]#{perm}{2}(?<perms>#{other}) +\d+ +#{lows} +#{lows} +\d+ +#{month} +\d+ +#{yt} +(?<name>#{filename})$/
end

def vr_re
   num = /[0-9]+/
   neg = /-?#{num}/
   pos = /\+?#{num}/
   reg = /\/\w+\//
   exp = /#{num}|\.|\$|\.#{neg}|\.#{pos}|#{reg}/

   /^(?<from>#{exp})(?<to>$)|^(?<from>#{exp}),(?<to>#{exp})$/
end

def path_re
   di = /^.*\/|^/
   ba = /[A-Za-z\-_0-9]*/
   ex = /\w*(\.\w+)*/


   /(?<dir>#{di})(?<base>#{ba})(\.(?<ext>#{ex}))?$/
end
