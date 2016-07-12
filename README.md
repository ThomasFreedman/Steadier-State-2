# Steadier-State-2
An updated version of Mark Minasi's [Steadier State](http://www.steadierstate.com/)

I am the IT guy for a local volunteer library that provides a small number of public use computers. 
Surprisingly, I didn’t discover Mark Minasi’s Steadier State until this year (2016), although I have 
conducted numerous searches related to the original Steady State program Micro$oft chose to discontinue, 
and the built-in version of it initially bundled with early prereleases of Windows 7. 
Our library is a non-profit organization that receives no subsidies from any government agency and the staff
is comprised entirely of volunteers.  The operating budget is generated from the sales of books, donations 
and the $1 and hour fee charged to use the computers.

I have been volunteering my IT services for the past 5 years and it has kept me quite busy dealing with 
issues brought on by patrons that inadvertently manage to infect the computers with viruses or do things 
that require my attention to fix, not to mention issues Micro$oft introduces via Windows Updates. Besides
myself, the library staff has no expertise or desire to manage these issues or help patrons with anything 
but the most basic computer problems.

Micro$oft doesn’t make it easy for organizations such as our library to run public use computers. I have 
intended to replace Microsoft Windows with Linux at some point, but most users here are so computer 
illiterate that such a replacement would be viewed with significant resistance.  If such a change is
to occur, it must take place gradually and by the user’s own prerogative. That’s only fitting for an all
volunteer organization don’t you think?

Another hurdle I had to jump was convincing the library board to cover the cost of upgrading the Windows 
licenses from Professional to Ultimate. Fortunately this was not as difficult as I anticipated, due in part 
from the low cost of OEM licenses I obtained on ebay 2 years ago and the improvements to reliability and 
performance that results from running an OS that doesn’t accumulate crud in the user’s profile and system 
registry.  It is to this last point that Mark Minasi’s Steadier State has been a huge advantage. 

Although as originally designed Steadier State requires more time to boot into a steady state, 
Mr. Minasi’s generous work illustrated the concept very well of how to run Windows from a virtualized VHD filesystem, 
and paved the way for the changes I implemented to reduce the boot up time by eliminating the secondary 
[Win PE](https://en.wikipedia.org/wiki/Windows_Preinstallation_Environment) boot cycle his approach required. 

The essential innovation was conceived by user cdob on the [reboot.pro](http://reboot.pro/), 
a forum where IT professionals and computer enthusiasts discuss issues and problems, mostly but not
exclusively related to Microsoft Windows. Although [I came up with the general approach](http://reboot.pro/topic/21148-boot-vhd-or-winpe-with-grub2/#entry199203) 
of using the boot loader rather than Win PE to replace the VHD files with fresh, pristine “template” versions, 
[it was user cdob that suggested](http://reboot.pro/topic/21148-boot-vhd-or-winpe-with-grub2/#entry199206) to 
use boot manager entries and alternate between them to achieve the same result. Based on that suggestion 
I wrote a shutdown script that toggles the default boot manger entry to test the idea. It worked perfectly, 
and from there I decided to revise Mark Minasi’s Steadier State scripts to take advantage of this new approach. 

It was further [suggested by user “Wonko the Sane”](http://reboot.pro/topic/21148-boot-vhd-or-winpe-with-grub2/#entry199211)
on the reboot.pro forum that I could use [iPXE’s “wimboot”](http://ipxe.org/wimboot) to load Win PE 
directly from the grub2 menu, which eliminated the need for a dedicated partition to hold Win PE files. 
Win PE is required for maintenance of the parent template VHD file, for example to merge in Windows 
updates or make other changes deemed necessary.  So now you have the history and motivation for these changes. 
I sincerely hope you find them useful. You may contact me on 
[reboot.pro via the user thomnet](http://reboot.pro/user/67663-thomnet/).
