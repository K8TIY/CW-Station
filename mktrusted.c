/*
Copyright © 2010-2011 Brian S. Hall

This program is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License version 2 as
published by the Free Software Foundation.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program. If not, see <http://www.gnu.org/licenses/>.
*/
#include <CoreFoundation/CoreFoundation.h>
#include <ApplicationServices/ApplicationServices.h>

int main(int argc, const char *argv[])
{
  // Is this process running as root?
  if (geteuid() != 0)
  {
    fprintf(stderr, "Not running as root\n");
    exit(-1);
  }
  // Was there one argument?
  if (argc != 2)
  {
    fprintf(stderr, "Usage: mktrusted <dir>\n");
    exit(-1);
  }
  CFStringRef path = CFStringCreateWithCString(kCFAllocatorDefault, argv[1], kCFStringEncodingUTF8); 
  AXError err = AXMakeProcessTrusted(path);
  CFRelease(path);
  return err;
}

