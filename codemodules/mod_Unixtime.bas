Attribute VB_Name = "mod_Unixtime"
'ignitionServer is (C)  Keith Gable and Nigel Jones.
'----------------------------------------------------
'You must include this notice in any modifications you make. You must additionally
'follow the GPL's provisions for sourcecode distribution and binary distribution.
'If you are not familiar with the GPL, please read LICENSE.TXT.
'(you are welcome to add a "Based On" line above this notice, but this notice must
'remain intact!)
'Released under the GNU General Public License
'Contact information: Keith Gable (Ziggy) <ziggy@ignition-project.com>
'                     Nigel Jones (DigiGuy) <digiguy@ignition-project.com>
'
'ignitionServer is based on Pure-IRCd <http://pure-ircd.sourceforge.net/>
'
' $Id: mod_Unixtime.bas,v 1.3 2004/05/28 20:35:05 ziggythehamster Exp $
'
'
'This program is free software.
'You can redistribute it and/or modify it under the terms of the
'GNU General Public License as published by the Free Software Foundation; either version 2 of the License,
'or (at your option) any later version.
'
'This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY.
'Without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
'See the GNU General Public License for more details.
'
'You should have received a copy of the GNU General Public License along with this program.
'if not, write to the Free Software Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA 02111-1307 USA

Option Explicit
Private Type SYSTEMTIME
  wYear As Integer
  wMonth As Integer
  wDayOfWeek As Integer
  wDay As Integer
  wHour As Integer
  wMinute As Integer
  wSecond As Integer
  wMilliseconds As Integer
End Type

Private Type TIME_ZONE_INFORMATION
  Bias As Long
  StandardName(63) As Byte
  StandardDate As SYSTEMTIME
  StandardBias As Long
  DaylightName(63) As Byte
  DaylightDate As SYSTEMTIME
  DaylightBias As Long
End Type

Private Const TIME_ZONE_ID_INVALID As Long = &HFFFFFFFF
Private Const TIME_ZONE_ID_UNKNOWN As Long = 0&
Private Const TIME_ZONE_ID_STANDARD As Long = 1&
Private Const TIME_ZONE_ID_DAYLIGHT As Long = 2&

Private Declare Function GetTimeZoneInformation Lib "kernel32" (lpTimeZoneInformation As TIME_ZONE_INFORMATION) As Long

Public Sub InitUnixTime()
  Dim tzi As TIME_ZONE_INFORMATION
  UnixTime = DateDiff("s", DateValue("1/1/1970"), Now)
  Call GetTimeZoneInformation(tzi)
  UnixTime = UnixTime + (tzi.Bias * 60)
End Sub
