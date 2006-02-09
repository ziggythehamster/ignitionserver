Attribute VB_Name = "modSox"
'ignitionServer is (C)  Keith Gable, Nigel Jones and Reid Burke.
'----------------------------------------------------
'You must include this notice in any modifications you make. You must additionally
'follow the GPL's provisions for sourcecode distribution and binary distribution.
'If you are not familiar with the GPL, please read LICENSE.TXT.
'(you are welcome to add a "Based On" line above this notice, but this notice must
'remain intact!)
'Released under the GNU General Public License
'Contact information: Keith Gable (Ziggy) <ziggy@ignition-project.com>
'                     Nigel Jones (DigiGuy) <digiguy@ignition-project.com>
'                     Reid Burke  (AirWalk) <airwalk@ignition-project.com>
'
'ignitionServer is based on Pure-IRCd <http://pure-ircd.sourceforge.net/>
'
' $Id: modSox.bas,v 1.2 2004/06/29 01:52:57 ziggythehamster Exp $
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
Const WSADescription_Len = 256
Const WSASYS_Status_Len = 128
Private Type HOSTENT
  hName As Long
  hAliases As Long
  hAddrType As Integer
  hLength As Integer
  hAddrList As Long
End Type
Private Type WSADATA
  wversion As Integer
  wHighVersion As Integer
  szDescription(0 To WSADescription_Len) As Byte
  szSystemStatus(0 To WSASYS_Status_Len) As Byte
  iMaxSockets As Integer
  iMaxUdpDg As Integer
  lpszVendorInfo As Long
End Type
Private Declare Function WSAGetLastError Lib "WSOCK32" () As Long
Private Declare Function gethostbyaddr Lib "WSOCK32" (addr As Long, addrLen As Long, addrType As Long) As Long
Private Declare Function gethostbyname Lib "WSOCK32" (ByVal hostname As String) As Long
Private Declare Sub RtlMoveMemory Lib "kernel32" (hpvDest As Any, ByVal hpvSource As Long, ByVal cbCopy As Long)

Public Function WindowProc(ByVal hWnd As Long, ByVal uMsg As Long, ByVal wParam As Long, ByVal lParam As Long) As Long
On Error Resume Next
    Let WindowProc = Sockets.WndProc(hWnd, uMsg, wParam, lParam)
End Function

Public Sub Sox_Close(insox As Long)
On Error Resume Next
InternalDebug "Socket Closed"
myInSox = insox
mySocketHandle = Sockets.SocketHandle(insox)
CanKill = True
End Sub

Public Sub Sox_Connect(insox As Long, IsClient As Boolean)
On Error Resume Next
'we connected!
InternalDebug "Connected! (" & insox & ")"
If StopIS = True Then
  InternalDebug "Stopping...!"
  Dim F As Long
  Dim TheNumber As Long
  F = FreeFile
  Randomize Timer
  TheNumber = Int(Rnd * 1000)
  Open App.Path & "\monitor.id" For Output As F
  Print #F, TheNumber
  Close #F
  InternalDebug "Killing with ID " & TheNumber
  Dim bArr() As Byte
  bArr = StrConv("MDIE " & TheNumber & vbCrLf, vbFromUnicode)
  Call Send(Sockets.SocketHandle(insox), bArr(0), UBound(bArr) + 1, 0)
  InternalDebug "Sent it..."
  mySocketHandle = Sockets.SocketHandle(insox)
  myInSox = insox
  CanKill = True
End If
End Sub

Public Sub Sox_DataArrival(insox As Long, StrMsg As String)
On Error Resume Next
InternalDebug "Data: " & StrMsg
End Sub

Public Sub Sox_Error(insox As Long, inerror As Long, inDescription As String, inSource As String, inSnipet As String)
On Error Resume Next
InternalDebug "Error #" & inerror & ": " & inDescription
myInSox = insox
mySocketHandle = Sockets.SocketHandle(insox)
CanKill = True
End Sub

'checks if string is valid IP address
Public Function IsIP(ByVal strIP As String) As Boolean
  On Error Resume Next
  Dim t As String: Dim s As String: Dim I As Integer
  s = strIP
  While InStr(s, ".") <> 0
    t = Left$(s, InStr(s, ".") - 1)
    If IsNumeric(t) And Val(t) >= 0 And Val(t) <= 255 Then s = Mid$(s, InStr(s, ".") + 1) _
      Else Exit Function
    I = I + 1
  Wend
  t = s
  If IsNumeric(t) And InStr(t, ".") = 0 And Len(t) = Len(Trim$(Str$(Val(t)))) And _
    Val(t) >= 0 And Val(t) <= 255 And strIP <> "255.255.255.255" And I = 3 Then IsIP = True
  If Err.Number > 0 Then
    Err.Clear
  End If
End Function

'converts IP address from string to sin_addr
Private Function MakeIP(strIP As String) As Long
  On Error Resume Next
  Dim lIP As Long
  lIP = Left$(strIP, InStr(strIP, ".") - 1)
  strIP = Mid$(strIP, InStr(strIP, ".") + 1)
  lIP = lIP + Left$(strIP, InStr(strIP, ".") - 1) * 256
  strIP = Mid$(strIP, InStr(strIP, ".") + 1)
  lIP = lIP + Left$(strIP, InStr(strIP, ".") - 1) * 256 * 256
  strIP = Mid$(strIP, InStr(strIP, ".") + 1)
  If strIP < 128 Then
    lIP = lIP + strIP * 256 * 256 * 256
  Else
    lIP = lIP + (strIP - 256) * 256 * 256 * 256
  End If
  MakeIP = lIP
  If Err.Number > 0 Then
    Err.Clear
  End If
End Function

'resolves IP address to host name
Private Function NameByAddr(ByVal strAddr As String) As String
  On Error Resume Next
  Dim nRet As Long
  Dim lIP As Long
  Dim strHost As String * 255: Dim strTemp As String
  Dim hst As HOSTENT
  
  If IsIP(strAddr) Then
    lIP = MakeIP(strAddr)
    nRet = gethostbyaddr(lIP, 4, 2)
    If nRet <> 0 Then
      RtlMoveMemory hst, nRet, Len(hst)
      RtlMoveMemory ByVal strHost, hst.hName, 255
      strTemp = strHost
      If InStr(strTemp, vbLf) <> 0 Then strTemp = Left$(strTemp, InStr(strTemp, vbNullChar) - 1)
      strTemp = Trim$(strTemp)
      NameByAddr = strTemp
    Else
      Exit Function
    End If
  Else
    Exit Function
  End If
  If Err.Number > 0 Then
    Err.Clear
  End If
End Function

'resolves host name to IP address
Private Function AddrByName(ByVal strHost As String)
  On Error Resume Next
  Dim hostent_addr As Long
  Dim hst As HOSTENT
  Dim hostip_addr As Long
  Dim temp_ip_address() As Byte
  Dim I As Integer
  Dim ip_address As String
  If IsIP(strHost) Then
    AddrByName = strHost
    Exit Function
  End If
  hostent_addr = gethostbyname(strHost)
  If hostent_addr = 0 Then
    Exit Function
  End If
  RtlMoveMemory hst, hostent_addr, LenB(hst)
  RtlMoveMemory hostip_addr, hst.hAddrList, 4
  ReDim temp_ip_address(1 To hst.hLength)
  RtlMoveMemory temp_ip_address(1), hostip_addr, hst.hLength
  For I = 1 To hst.hLength
    ip_address = ip_address & temp_ip_address(I) & "."
  Next
  ip_address = Mid$(ip_address, 1, Len(ip_address) - 1)
  AddrByName = ip_address
  If Err.Number > 0 Then
    Err.Clear
  End If
End Function

Public Function AddressToName(strIP As String)
  AddressToName = StripTerminator(NameByAddr(strIP))
  If Len(AddressToName) = 0 Then AddressToName = strIP
End Function

Public Function NameToAddress(strName As String)
  NameToAddress = StripTerminator(AddrByName(strName))
  If Len(NameToAddress) = 0 Then NameToAddress = strName
End Function

Private Function StripTerminator(ByVal strString As String) As String
    Dim intZeroPos As Long
    intZeroPos = InStr(strString, vbNullChar)
    If intZeroPos > 0 Then
        StripTerminator = Left$(strString, intZeroPos - 1)
    Else
        StripTerminator = strString
    End If
End Function
