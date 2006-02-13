Attribute VB_Name = "mod_user"
'ignitionServer is (C) Keith Gable and Contributors
'----------------------------------------------------
'You must include this notice in any modifications you make. You must additionally
'follow the GPL's provisions for sourcecode distribution and binary distribution.
'If you are not familiar with the GPL, please read LICENSE.TXT.
'(you are welcome to add a "Based On" line above this notice, but this notice must
'remain intact!)
'Released under the GNU General Public License
'
'Contact information: Keith Gable (Ziggy) <ziggy@ignition-project.com>
'Contributors:        Nigel Jones (DigiGuy) <digi_guy@users.sourceforge.net>
'                     Reid Burke  (Airwalk) <airwalk@ignition-project.com>
'
'ignitionServer is based on Pure-IRCd <http://pure-ircd.sourceforge.net/>
'
' $Id: mod_user.bas,v 1.63 2004/12/31 00:22:39 ziggythehamster Exp $
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
#Const SendMessageOnInvalidLogin = 1
#Const Debugging = 0

Public Function do_nick_name(Nick$) As Long
#If Debugging = 1 Then
    SendSvrMsg "DoNickName called! (" & Nick & ")"
#End If
Dim i&
'A'..'}', '_', '-', '0'..'9'
If IsNumeric(Left$(Nick, 1)) Then Exit Function
If Left$(Nick, 1) = "-" Then Exit Function
If StrComp(LCase$(Nick), "anonymous", vbTextCompare) = 0 Then Exit Function
For i = 1 To Len(Nick)
    If Not IsValidString(Mid$(Nick, i, 1)) Then Exit Function
Next i
do_nick_name = 1
End Function
Public Function do_user_name(User$) As Long
#If Debugging = 1 Then
    SendSvrMsg "DoUserName called! (" & User & ")"
#End If
Dim i&
'A'..'}', '_', '-', '0'..'9'
If IsNumeric(Left$(User, 1)) Then Exit Function
If Left$(User, 1) = "-" Then Exit Function
If StrComp(User, "anonymous", vbTextCompare) = 0 Then Exit Function
For i = 1 To Len(User)
    If Not IsValidUserString(Mid$(User, i, 1)) Then Exit Function
Next i
do_user_name = 1
End Function

Public Function IsValidString(ByRef strString$) As Boolean
#If Debugging = 1 Then
    SendSvrMsg "IsValidString called! (" & strString & ")"
#End If
    Dim strAsc%
    strAsc = AscW(strString)
    If Not IsNumeric(strString) Then
        If strAsc < 65 And strString <> "-" Then
            Exit Function
        ElseIf (strAsc > 96 And strAsc < 97) Then
            Exit Function
        'ElseIf (strAsc > 122 And strString <> "_") Then
        ElseIf (strAsc > 125 And strString <> "_") Then
            Exit Function
        ElseIf (strAsc = 94) Then
            Exit Function
        End If
    End If
    IsValidString = True
End Function
Public Function IsValidUserString(ByRef strString$) As Boolean
#If Debugging = 1 Then
    SendSvrMsg "IsValidUserString called! (" & strString & ")"
#End If
    Dim strAsc%
    strAsc = AscW(strString)
    If Not IsNumeric(strString) Then
        If strAsc < 65 And strString <> "-" Then
            Exit Function
        ElseIf (strAsc > 96 And strAsc < 97) Then
            Exit Function
        ElseIf (strAsc > 122 And strString <> "_") Then
            Exit Function
        End If
    End If
    IsValidUserString = True
End Function

'/*
'** m_nick
'**  parv[0] = sender prefix
'**  parv[1] = nickname
'** the following are only used between servers since version 2.9
'**  parv[2] = hopcount
'**  parv[3] = username (login name, account)
'**  parv[4] = client host name
'**  parv[5] = server token
'**  parv[6] = users mode
'**  parv[7] = users real name info
'*/
'Set /nick help here
Public Function m_nick(cptr As clsClient, sptr As clsClient, parv$()) As Long
On Error GoTo NickError
Dim WhereAmI As String
WhereAmI = "entry"
#If Debugging = 1 Then
    SendSvrMsg "NICK called! (" & cptr.Nick & ")"
#End If
Dim pdat$, i&, tempVar$
If cptr.AccessLevel = 4 Then
    WhereAmI = "server nick"
    ':Nick NICK Nick2
    '  -2   -1   0
    'negative numbers don't count ;)
    
    If UBound(parv) > 0 Then
        #If Debugging = 1 Then
          SendSvrMsg "server nick - ubound(parv) > 0"
        #End If
        Dim NewCptr As clsClient, MSwitch As Boolean
        MSwitch = True
        WhereAmI = "getting global user... (" & parv(0) & ")"
        Set NewCptr = GlobUsers(parv(0))
        If Not NewCptr Is Nothing Then
            WhereAmI = "nick collision"
            #If Debugging = 1 Then
              SendSvrMsg "*** Nickname Collision (" & parv(0) & ") (from: " & cptr.Host & ") (exists from: " & NewCptr.Host & ")"
            #End If
            'm_error NewCptr, "Nick Collision"
            '// kill the user already on the server, but do it cleanly
            Dim NewParv(1) As String
            NewParv(0) = NewCptr.Nick
            NewParv(1) = "Nickname collision from " & cptr.ServerName
            
            m_kill Servers(ServerName), NewCptr.FromLink, NewParv, True
            '// we allow the new user to exist because it would cause
            '// "attacks" of automated clients such as services, if services has a
            '// reconnect-on-kill feature (ignitionServices does)
            '// Additionally, ignitionServer will properly close it at both ends
            '// (well, it should), because this part is only executed if the new
            '// client exists locally -- it exists locally on both servers, and
            '// when one introduces it, the other removes it (and then when the
            '// opposite end introduces it, this end removes it). Or something like
            '// that.
        End If
        WhereAmI = "newcptr = newclient"
        Set NewCptr = New clsClient
        WhereAmI = "set hops"
        NewCptr.Hops = CLng(parv(1))
        WhereAmI = "add global user"
        Set NewCptr = GlobUsers.Add(parv(0), NewCptr)
        WhereAmI = "newcptr is nothing"
        If NewCptr Is Nothing Then Exit Function
        WhereAmI = "set newcptr options"
        With NewCptr
            WhereAmI = "set accesslevel"
            .AccessLevel = 1
            WhereAmI = "set nick"
            .Nick = parv(0)
            WhereAmI = "set signon time"
            .SignOn = CLng(parv(2))
            WhereAmI = "set user"
            .User = parv(3)
            WhereAmI = "set host"
            If MaskDNS = True Then
                If MaskDNSMD5 = True Then
                    .Host = UCase$(modMD5.oMD5.MD5(parv(4)))
                ElseIf MaskDNSHOST = True Then
                    If Not HostMask = vbNullString Then
                        .Host = .Nick & "." & HostMask
                    Else
                        MaskDNSHOST = False
                        MaskDNSMD5 = True
                    End If
                End If
            Else
                .Host = parv(4)
            End If
            WhereAmI = "set realhost"
            .RealHost = parv(4)
            WhereAmI = "set prefix"
            .Prefix = ":" & .Nick & "!" & .User & "@" & .Host
            WhereAmI = "set server desc"
            .ServerDescription = sptr.ServerDescription
            WhereAmI = "set server name"
            .ServerName = parv(5)
            WhereAmI = "set name"
            .Name = parv(6)
            WhereAmI = "set from link"
            Set .FromLink = cptr
            WhereAmI = "increase global users"
            IrcStat.GlobUsers = IrcStat.GlobUsers + 1
            WhereAmI = "increase max users, if needed"
            'If IrcStat.MaxGlobUsers < IrcStat.GlobUsers Then IrcStat.MaxGlobUsers = IrcStat.MaxGlobUsers + 1
            If IrcStat.MaxGlobUsers < GlobUsers.Count Then IrcStat.MaxGlobUsers = GlobUsers.Count
            WhereAmI = "propragate signon"
            SendToServer_ButOne "NICK " & .Nick & " " & .Hops + 1 & " " & .SignOn & " " & .User & " " & .RealHost & _
            " " & .ServerName & " :" & .Name, cptr.ServerName, sptr.ServerName
        End With
        WhereAmI = "end set newcptr options"
        #If Debugging = 1 Then
          SendSvrMsg "nick set by server; host: " & NewCptr.RealHost & " name: " & NewCptr.Name & " nick: " & NewCptr.Nick
        #End If
    Else
        WhereAmI = "server nick, no params"
        #If Debugging = 1 Then
          SendSvrMsg "server nick - ubound(parv) else [<=0] (nick change?)"
        #End If
        SendToServer_ButOne "NICK " & parv(0), cptr.ServerName, sptr.Nick
        'this is a raw send
        'perhaps we should clean this up a bit?
        'FIXME: don't use a raw send here
        Dim ByteArr() As Byte, Members() As clsChanMember
        ByteArr = StrConv(sptr.Prefix & " NICK " & parv(0) & vbCrLf, vbFromUnicode)
        Dim RecvArr() As Long: ReDim RecvArr(0)
        For m_nick = 1 To cptr.OnChannels.Count
          Members = sptr.OnChannels.Item(m_nick).Member.Values
          For i = LBound(Members) To UBound(Members)
            If Members(i).Member.Hops = 0 Then
              If Not Members(i).Member Is sptr Then
                ReDim Preserve RecvArr(UBound(RecvArr) + 1)
                RecvArr(UBound(RecvArr)) = Members(i).Member.index
              End If
            End If
          Next i
        Next m_nick
        KillDupes RecvArr
        ServerTraffic = ServerTraffic + (UBound(RecvArr) * UBound(ByteArr))
        For i = 1 To UBound(RecvArr)
            Call Send(Sockets.SocketHandle(CLng(RecvArr(i))), ByteArr(0), UBound(ByteArr) + 1, 0&)
        Next i
        GlobUsers.Remove sptr.Nick
        sptr.Nick = parv(0)
        GlobUsers.Add parv(0), sptr
        sptr.Prefix = ":" & sptr.Nick & "!" & sptr.User & "@" & sptr.Host
    End If
Else
  WhereAmI = "use nick"
  Dim Temp$
  Dim ShowNick As String
  If Len(cptr.Nick) = 0 Then
    ShowNick = "Anonymous"
  Else
    ShowNick = cptr.Nick
  End If
  
  If Len(parv(0)) = 0 Then  'In case client didn't send a nick along -Dill
    WhereAmI = "no nickname given"
    SendWsock cptr.index, ERR_NONICKNAMEGIVEN & " " & ShowNick, TranslateCode(ERR_NONICKNAMEGIVEN)
    Exit Function
  End If
  If AscW(parv(0)) = 58 Then parv(0) = Mid$(parv(0), 2)
  If NickLen > 0 Then
    parv(0) = Mid$(parv(0), 1, NickLen)
  End If
  If StrComp(cptr.Nick, parv(0)) = 0 Then Exit Function
  WhereAmI = "check nick for illegal characters"
  If do_nick_name(parv(0)) = 0 Then 'in case client send a nick with illegal char's along -Dill
    SendWsock cptr.index, ERR_ERRONEUSNICKNAME & " " & ShowNick, TranslateCode(ERR_ERRONEUSNICKNAME, parv(0))
    Exit Function
  End If
  i = GetQLine(parv(0), cptr.AccessLevel)
  WhereAmI = "normal nick crap"
  If i > 0 Then
    'the original people added another parameter that didn't need to be there
    SendWsock cptr.index, ERR_ERRONEUSNICKNAME & " " & parv(0), QLine(i).Reason & " [" & QLine(i).Nick & "]"
    Exit Function
  End If
  If Not GlobUsers(parv(0)) Is Nothing Then  'in case the nickname specified is already in use -Dill
    SendWsock cptr.index, ERR_NICKNAMEINUSE & " " & ShowNick, TranslateCode(ERR_NICKNAMEINUSE, parv(0))
    Exit Function
  End If
  WhereAmI = "entering main code"
  #If Debugging = 1 Then
    SendSvrMsg "NICK: entering main code"
  #End If
  If cptr.OnChannels.Count > 0 Then
    WhereAmI = "check if banned"
    #If Debugging = 1 Then
      SendSvrMsg "NICK: main code -> check if banned"
    #End If
    For m_nick = 1 To cptr.OnChannels.Count 'in case nick is banned on a channel he is currently on -Dill
      If IsBanned(cptr.OnChannels.Item(m_nick), cptr) Then
        SendWsock cptr.index, ERR_BANNICKCHANGE & " " & cptr.OnChannels.Item(m_nick).Name, "Cannot change nickname while banned on channel"
        Exit Function
      End If
    Next m_nick
    
    'This is an really bad solution, as it uses up too much mem and cpu
    'but i wasnt yet able to come up with another one that was working.
    'i have tried an array and then kill dupes off, so each visible client
    'is sent exactly one nick message but that didnt work right... -Dill
    
    WhereAmI = "notifying all visible members"
    #If Debugging = 1 Then
      SendSvrMsg "NICK: main code -> notifying all visible members"
    #End If
    
    Dim AllVisible As New Collection
    ReDim RecvArr(1)
    For m_nick = 1 To cptr.OnChannels.Count
      Members = cptr.OnChannels.Item(m_nick).Member.Values
      For i = LBound(Members) To UBound(Members)
        If Members(i).Member.Hops = 0 Then
          If Not Members(i).Member Is cptr Then
            On Local Error Resume Next
            AllVisible.Add Members(i).Member.index, CStr(Members(i).Member.index)
          End If
        End If
      Next i
    Next m_nick
    
    WhereAmI = "sending nickname stuff"
    #If Debugging = 1 Then
      SendSvrMsg "NICK: main code -> sending nickname stuff"
    #End If
    
    For i = 1 To AllVisible.Count
      Call SendWsock(AllVisible(i), "NICK", ":" & parv(0), cptr.Prefix)
    Next i
    SendToServer "NICK :" & parv(0), cptr.Nick
  Else
    If Len(cptr.Nick) > 0 Then
      WhereAmI = "user on no channels, notify other servers"
      #If Debugging = 1 Then
        SendSvrMsg "NICK: main code -> user on no channels, notify other servers"
      #End If
      
      SendToServer "NICK :" & parv(0), cptr.Nick
    End If
  End If
  'if the user is not currently registering, tell it the new nickname -Dill
  WhereAmI = "bad password"
  If Len(cptr.Nick) = 0 Then
    If cptr.IIndex <= 0 Then
      ErrorMsg "CRITICAL ERROR: There is a serious configuration error. The client connecting from " & cptr.IP & " has an invalid IIndex of " & cptr.IIndex & ". You have improperly set up I: lines, or improperly set up Y: lines. Please check them to ensure they are properly configured."
      Exit Function
    End If
    If cptr.IIndex > UBound(ILine) Then
      'the IIndex is > the highest ILine
      ErrorMsg "CRITICAL ERROR: There is a serious configuration error. The client connecting from " & cptr.IP & " has an invalid IIndex of " & cptr.IIndex & ". You have improperly set up I: lines, or improperly set up Y: lines. Please check them to ensure they are properly configured."
      Exit Function
    End If
    
    'verify this in USER -zg
    
    'If Len(ILine(cptr.IIndex).Pass) > 0 Then
    '  If cptr.PassOK = False Then
    '      m_error cptr, "Closing Link: (Bad Password)"
    '      #If Debugging = 1 Then
    '        SendSvrMsg "m_nick : bad password (vfy against '" & ILine(cptr.IIndex).Pass & "' iidx " & cptr.IIndex
    '      #End If
    '      KillStruct cptr.Nick, , False, cptr.IP
    '      Exit Function
    '  End If
    'Else
    '  cptr.PassOK = True
    'End If
    If OfflineMode = True Then
        If Len(OfflineMessage) = 0 Then
            'For x = 1 To .OnChannels.Count
            '    SendToChan .OnChannels.Item(x), .Prefix & " AutoKilled: Server In Offline Mode", vbNullString
            'Next x
            SendToServer "QUIT :AutoKilled: Server In Offline Mode", cptr.Nick
            SendWsock cptr.index, "KILL " & cptr.Nick, ":AutoKilled: Server In Offline Mode", cptr.Prefix
            m_error cptr, "Closing Link: (AutoKilled: Server In Offline Mode)"
            cptr.IsKilled = True
            KillStruct cptr.Nick, , False, cptr.IP
            Exit Function
        Else
            'For x = 1 To .OnChannels.Count
            '    SendToChan .OnChannels.Item(x), .Prefix & " AutoKilled: " & OfflineMessage, vbNullString
            'Next x
            SendToServer "QUIT :AutoKilled: " & OfflineMessage, cptr.Nick
            SendWsock cptr.index, "KILL " & cptr.Nick, ":AutoKilled: " & OfflineMessage, cptr.Prefix
            m_error cptr, "Closing Link: (AutoKilled: " & OfflineMessage & ")"
            cptr.IsKilled = True
            KillStruct cptr.Nick, , False, cptr.IP
            Exit Function
        End If
    End If
    'if they've already sent USER, send this stuff
    'this will ensure they don't become a user before
    'verifying the password
    If Len(cptr.User) > 0 And Not cptr.SentLogonNotices Then
      pdat = GetRand
      WhereAmI = "ping timeouts"
      SendWsock cptr.index, "NOTICE AUTH", ":*** If you experience problems while connecting please email the admin (" & mod_list.AdminEmail & ") about it and include the server you tried to connect to (" & ServerName & ")."
      SendWsock cptr.index, "NOTICE AUTH", ":*** If you experience problems due to PING timeouts, type '/QUOTE PONG :" & pdat & "' or '/RAW PONG :" & pdat & "' now."
      WhereAmI = "custom auth notice"
      If Not Len(CustomNotice) = 0 Then 'moved so user will always see notice -AW
          SendWsock cptr.index, "NOTICE AUTH", ":*** " & CustomNotice
      End If
      SendWsock cptr.index, "PING " & pdat, vbNullString, , True
      IrcStat.UnknownConnections = IrcStat.UnknownConnections - 1
      cptr.SentLogonNotices = True
    End If
  Else
    WhereAmI = "set nickname"
    pdat = parv(0)
    SendWsock cptr.index, "NICK", ":" & pdat, cptr.Prefix
  End If
  
  WhereAmI = "assign new nick to user"
  'assign the new nick to the database -Dill
  tempVar = cptr.Nick
  If Len(cptr.Nick) > 0 Then GenerateEvent "USER", "NICK", Replace(cptr.Prefix, ":", ""), Replace(cptr.Prefix, ":", "") & " " & parv(0)
  If Len(cptr.Nick) > 0 Then GlobUsers.Remove cptr.Nick
  GlobUsers.Add parv(0), cptr
  cptr.Nick = parv(0)
  cptr.Prefix = ":" & cptr.Nick & "!" & cptr.User & "@" & cptr.Host
  
  WhereAmI = "assign new nick to database"
  Dim WasOwner As Boolean, WasOp As Boolean, WasVoice As Boolean
  Dim tmpRetVal As Long
  Dim tmpData As Long
  
  If cptr.OnChannels.Count > 0 Then
    WhereAmI = "onchannels > 0"
    For tmpRetVal = 1 To cptr.OnChannels.Count
         With cptr.OnChannels.Item(tmpRetVal).Member
           WhereAmI = "checking wasowner"
           WasOwner = .Item(tempVar).IsOwner
           WhereAmI = "checking wasop"
           WasOp = .Item(tempVar).IsOp
           WhereAmI = "checking wasvoice"
           WasVoice = .Item(tempVar).IsVoice
           WhereAmI = "doing bitmasks"
           tmpData = 0
           If WasOwner Then tmpData = 6
           If WasOp Then tmpData = 4 'WTF is this bit for? Any Ideas Ziggy? - DG
                                  'looks like a temp variable for the user level - Ziggy
           If WasVoice Then tmpData = tmpData + 1
           .Remove tempVar
           .Add CLng(tmpData), cptr
         End With
    Next tmpRetVal
    m_nick = tmpRetVal
  End If
End If
Exit Function

NickError:
ErrorMsg "Error " & err.Number & " (" & err.Description & ") in 'm_nick' at " & WhereAmI
End Function

'/*
'** m_message (used in m_private() and m_notice())
'** the general function to deliver MSG's between users/channels
'**
'**  parv[0] = sender prefix
'**  parv[1] = receiver list
'**  parv[2] = message text
'**
'** massive cleanup
'** rev argv 6/91
'**
'*/
Public Function m_message(cptr As clsClient, sptr As clsClient, parv$(), Notice As Boolean) As Long
#If Debugging = 1 Then
    SendSvrMsg "PRIVMSG/NOTICE called! (" & cptr.Nick & ")"
#End If
Dim cmd$, RecList$(), i, x&, Chan As clsChannel, Recp As clsClient, RecvServer() As clsClient, ChM As clsChanMember
If cptr.AccessLevel = 4 Then
    If Notice Then
        cmd = "NOTICE"
    Else
        cmd = "PRIVMSG"
    End If
    RecList = Split(parv(0), ",")
    For Each i In RecList
        If AscW(CStr(i)) = 35 Then
            Set Chan = Channels(CStr(i))
            If Chan Is Nothing Then GoTo NextCmd
            If Chan.IsAuditorium Then
              If ((Chan.Member.Item(sptr.Nick).IsOwner) Or (Chan.Member.Item(sptr.Nick).IsOp)) Then
                If SendToChan(Chan, sptr.Prefix & " " & cmd & " " & Chan.Name & " :" & parv(1), cptr.Nick) Then
                  SendToServer_ButOne cmd & " " & Chan.Name & " :" & parv(1), cptr.ServerName, sptr.Nick
                End If
              Else
                'not +qo
                If SendToChanOps(Chan, sptr.Prefix & " " & cmd & " " & Chan.Name & " :" & parv(1), cptr.Nick) Then
                  SendToServer_ButOne cmd & " " & Chan.Name & " :" & parv(1), cptr.ServerName, sptr.Nick
                End If
              End If
            Else
              If SendToChan(Chan, sptr.Prefix & " " & cmd & " " & Chan.Name & " :" & parv(1), cptr.Nick) Then
                  SendToServer_ButOne cmd & " " & Chan.Name & " :" & parv(1), cptr.ServerName, sptr.Nick
              End If
            End If
            If Len(cmd) = 6 And LogChannels = True Then 'notice
              LogChannel Chan.Name, "-" & sptr.Nick & "- " & parv(1)
            ElseIf Len(cmd) = 7 And LogChannels = True Then 'privmsg
              LogChannel Chan.Name, "<" & sptr.Nick & "> " & parv(1)
            End If
        Else
            Set Recp = GlobUsers(CStr(i))
            If Recp Is Nothing Then
                'SendWsock cptr.Index, "KILL " & CStr(i), ":" & i & " <-- Unknown client"
                GoTo NextCmd
            End If
            If Recp.Hops > 0 Then
                'The user is an remote user
                SendWsock Recp.FromLink.index, cmd & " " & Recp.Nick, ":" & parv(1), ":" & sptr.Nick
            Else
                'the user is an local user
                SendWsock Recp.index, cmd & " " & Recp.Nick, ":" & parv(1), sptr.Prefix
            End If
            If Len(cmd) = 6 And LogUsers = True Then 'notice
              'if one user says it, both users get it logged
              LogUser sptr.Nick, "-" & sptr.Nick & "- " & parv(1)
              LogUser Recp.Nick, "-" & sptr.Nick & "- " & parv(1)
            ElseIf Len(cmd) = 7 And LogUsers = True Then 'privmsg
              LogUser sptr.Nick, "<" & sptr.Nick & "> " & parv(1)
              LogUser Recp.Nick, "<" & sptr.Nick & "> " & parv(1)
            End If
        End If
NextCmd:
    Next
Else
    If Len(parv(0)) = 0 Then 'if no recipient is given, return an error -Dill
      SendWsock cptr.index, ERR_NORECIPIENT & " " & cptr.Nick, TranslateCode(ERR_NORECIPIENT, cmd)
      Exit Function
    End If
    If UBound(parv) = 0 Then 'if cptr didnt tell us what to send, complain -Dill
      SendWsock cptr.index, ERR_NOTEXTTOSEND & " " & cptr.Nick, TranslateCode(ERR_NOTEXTTOSEND)
      Exit Function
    End If
    If Len(parv(1)) = 0 Then
      SendWsock cptr.index, ERR_NOTEXTTOSEND & " " & cptr.Nick, TranslateCode(ERR_NOTEXTTOSEND)
      Exit Function
    End If
    If cptr.IsGagged Then 'if they're gagged, they can't speak
      If BounceGagMsg Then SendWsock cptr.index, IRCERR_SECURITY & " " & cptr.Nick, TranslateCode(IRCERR_SECURITY)
      Exit Function
    End If
    If Notice Then
        cmd = " NOTICE "
    Else
        cmd = " PRIVMSG "
    End If
    RecList = Split(parv(0), ",")
    For Each i In RecList
      If Len(i) = 0 Then GoTo nextmsg
      If AscW(CStr(i)) = 35 Then
        'Channel message -Dill
        Set Chan = Channels(CStr(i))
        If Chan Is Nothing Then 'In case Channel does not exist -Dill
          SendWsock cptr.index, ERR_NOSUCHNICK, cptr.Nick & " " & TranslateCode(ERR_NOSUCHNICK, CStr(i))
          GoTo nextmsg
        End If
        With Chan
            If .IsNoExternalMsgs Then
                If .GetUser(cptr.Nick) Is Nothing Then
                  SendWsock cptr.index, ERR_CANNOTSENDTOCHAN, cptr.Nick & " " & TranslateCode(ERR_CANNOTSENDTOCHAN, .Name)
                  GoTo nextmsg
                End If
            End If
            If .IsModerated Then
              Set ChM = .Member.Item(cptr.Nick)
              If Not (ChM.IsVoice Or ChM.IsOp Or ChM.IsOwner) Then
                  SendWsock cptr.index, ERR_CANNOTSENDTOCHAN, cptr.Nick & " " & TranslateCode(ERR_CANNOTSENDTOCHAN, , .Name)
                  Set ChM = Nothing
                  GoTo nextmsg
              End If
              Set ChM = Nothing
            End If
            If IsBanned(Chan, cptr) Then
                SendWsock cptr.index, ERR_CANNOTSENDTOCHAN, cptr.Nick & " " & TranslateCode(ERR_CANNOTSENDTOCHAN, , .Name)
                GoTo nextmsg
            End If
            'Deliver the message -Dill
            If Chan.IsAuditorium Then
              If ((Chan.Member.Item(cptr.Nick).IsOwner) Or (Chan.Member.Item(cptr.Nick).IsOp)) Then
                If SendToChan(Chan, cptr.Prefix & cmd & Chan.Name & " :" & parv(1), cptr.Nick) Then
                  SendToServer Trim$(cmd) & " " & .Name & " :" & parv(1), cptr.Nick
                End If
              Else
                'not +qo
                If SendToChanOps(Chan, cptr.Prefix & cmd & Chan.Name & " :" & parv(1), cptr.Nick) Then
                  SendToServer Trim$(cmd) & " " & .Name & " :" & parv(1), cptr.Nick
                End If
              End If
            Else
              'not auditorium
              #If Debugging = 1 Then
                SendSvrMsg "*** not auditorium, send2chan"
              #End If
              If SendToChan(Chan, cptr.Prefix & cmd & .Name & " :" & parv(1), cptr.Nick) Then
                  SendToServer Trim$(cmd) & " " & .Name & " :" & parv(1), cptr.Nick
              #If Debugging = 1 Then
              Else
                SendSvrMsg "*** send2chan returned false"
              #End If
              End If '</send2chan>
            End If
           
        End With
        'reset idle time
        cptr.Idle = UnixTime
        #If Debugging = 1 Then
          SendSvrMsg "*** processing, len(cmd)=" & Len(cmd)
        #End If
        If Len(cmd) = 8 And LogChannels = True Then 'notice
          LogChannel Chan.Name, "-" & cptr.Nick & "- " & parv(1)
        ElseIf Len(cmd) = 9 And LogChannels = True Then 'privmsg
          LogChannel Chan.Name, "<" & cptr.Nick & "> " & parv(1)
        End If
      Else
        'user message -Dill
        If InStr(1, i, "*") <> 0 Then
          If Not (cptr.IsLocOperator Or cptr.IsGlobOperator) Then 'Can't send to wildcarded recipient list if not an oper -Dill
            SendWsock cptr.index, ERR_NOPRIVILEGES & " " & cptr.Nick, TranslateCode(ERR_NOPRIVILEGES)
            Exit Function
          Else
            'WILDCARD recievelist -Dill
            Dim Umask$, Target() As clsClient
            Umask = ":" & CreateMask(CStr(i))
            Target = GlobUsers.Values
            For x = LBound(Target) To UBound(Target)
                If Target(x).Prefix Like Umask Then
                    If Target(x).Hops = 0 Then
                        SendWsock Target(x).index, cmd & " " & Target(x).Nick, ":" & parv(1), cptr.Prefix
                    Else
                        SendWsock Target(x).FromLink.index, cmd & " " & Target(x).Nick, ":" & parv(1), ":" & cptr.Nick
                    End If
                End If
            Next x
            GoTo nextmsg
          End If
        End If
        On Local Error Resume Next
        Set sptr = GlobUsers(CStr(i))
        If sptr Is Nothing Then 'in case user does not exist -Dill
          SendWsock cptr.index, ERR_NOSUCHNICK, cptr.Nick & " " & TranslateCode(ERR_NOSUCHNICK, CStr(i))
          GoTo nextmsg
        End If
        'deliver the message -Dill
        If sptr.Hops = 0 Then
            SendWsock sptr.index, LTrim$(cmd) & sptr.Nick, ":" & parv(1), cptr.Prefix
        Else
            SendWsock sptr.FromLink.index, LTrim$(cmd) & sptr.Nick, ":" & parv(1), ":" & cptr.Nick
        End If
        If Len(sptr.AwayMsg) > 0 Then
            SendWsock cptr.index, RPL_AWAY & " " & cptr.Nick & " " & sptr.Nick, ":" & sptr.AwayMsg
        End If
        'reset idle time
        cptr.Idle = UnixTime
        If Len(cmd) = 8 And LogUsers = True Then 'notice
          'if one user says it, both users get it logged
          LogUser sptr.Nick, "-" & cptr.Nick & "- " & parv(1)
          LogUser cptr.Nick, "-" & cptr.Nick & "- " & parv(1)
        ElseIf Len(cmd) = 9 And LogUsers = True Then 'privmsg
          LogUser sptr.Nick, "<" & cptr.Nick & "> " & parv(1)
          LogUser cptr.Nick, "<" & cptr.Nick & "> " & parv(1)
        End If
      End If
nextmsg:
    Next
End If
End Function

'/*
'** m_who
'**  parv[0] = mask
'**  parv[1] = additional selection flag, only 'o' for now. (/who * o)
'*/

Public Function m_who(cptr As clsClient, sptr As clsClient, parv$()) As Long
#If Debugging = 1 Then
    SendSvrMsg "WHO called! (" & cptr.Nick & ")"
#End If
On Error Resume Next
Dim i&, x&, lastchan$, Chan As clsChannel, ChanMember As clsClient, ret As Long, Clients() As clsClient, ChM() As clsChanMember, ExtraInfo$
If cptr.AccessLevel = 4 Then
'TODO: /who from server (is this even possible)
Else
    Dim OperOnly As Boolean
    If Len(parv(0)) = 0 Then  'if no mask is given, complain -Dill
        SendWsock cptr.index, ERR_NEEDMOREPARAMS & " " & cptr.Nick, TranslateCode(ERR_NEEDMOREPARAMS, , , "WHO")
        Exit Function
    End If
    
    'extra flags!
    If UBound(parv) >= 1 Then
      If StrComp(parv(1), "o") = 0 Then
        OperOnly = True
      End If
    End If
    
    If AscW(parv(0)) = 35 Then
        Set Chan = Channels(parv(0))
        If Chan Is Nothing Then
            SendWsock cptr.index, SPrefix & " " & 315 & " " & cptr.Nick & " " & parv(0) & " :End of /WHO list.", vbNullString, , True
            Exit Function
        End If
        'if channel is private or secret, send nothing unless cptr is a member
        If Not cptr.IsOnChan(Chan.Name) Then
          If (Chan.IsPrivate) Or (Chan.IsSecret) Then
            SendWsock cptr.index, SPrefix & " " & 315 & " " & cptr.Nick & " " & parv(0) & " :End of /WHO list.", vbNullString, , True
            Exit Function
          End If
        End If
        ChM = Chan.Member.Values
        For i = LBound(ChM) To UBound(ChM)
            If MaxWhoLen > 0 Then
                If ret = MaxWhoLen Then
                    SendWsock cptr.index, 315 & " " & cptr.Nick & " " & parv(0), ":Too many matches"
                    Exit Function
                End If
            End If
            With ChM(i).Member
                If Len(.AwayMsg) > 0 Then
                    ExtraInfo = "G"
                Else
                    ExtraInfo = "H"
                End If
                If ChM(i).IsOwner Then
                    If cptr.IsIRCX Or cptr.AccessLevel = 4 Then
                      ExtraInfo = ExtraInfo & Level_Owner
                    Else
                      ExtraInfo = ExtraInfo & Level_Host
                    End If
                ElseIf ChM(i).IsOp And Not ChM(i).IsOwner Then  '// don't send erroneous chars
                    ExtraInfo = ExtraInfo & Level_Host
                ElseIf ChM(i).IsVoice And Not ChM(i).IsOwner And Not ChM(i).IsOp Then
                    ExtraInfo = ExtraInfo & Level_Voice
                End If
                If .IsGlobOperator Or .IsLocOperator Then ExtraInfo = ExtraInfo & "*"
                If .IsNetAdmin Then ExtraInfo = ExtraInfo & "A"
                If OperOnly = True Then
                  If Not (.IsGlobOperator Or .IsLocOperator) Then
                    ExtraInfo = vbNullString
                    GoTo SkipUserInChannel
                  End If
                End If
                SendWsock cptr.index, 352 & " " & cptr.Nick & " " & Chan.Name & " " & .User & " " & .Host & " " & ServerName & " " & .Nick & " " & ExtraInfo, ":" & .Hops & " " & .Name
                ExtraInfo = vbNullString
            End With
            ret = ret + 1
SkipUserInChannel:
        Next i
    Else
        Clients = GlobUsers.Values
        If Not Clients(0) Is Nothing Then
            For i = 0 To UBound(Clients)
                If MaxWhoLen > 0 Then
                    If ret = MaxWhoLen Then
                        SendWsock cptr.index, 315 & " " & cptr.Nick & " " & parv(0), ":Too many matches"
                        Exit Function
                    End If
                End If
                'TODO: clean up this code a little (lot?)
                If UCase$(Replace(Clients(i).Prefix, ":", "")) Like UCase$(CreateMask(Replace(parv(0), ":", ""))) Then
                    If Clients(i).OnChannels.Count > 0 And Not Clients(i).IsInvisible Then
                        If Not ((Channels(Clients(i).OnChannels.Item(Clients(i).OnChannels.Count).Name).IsSecret) Or (Channels(Clients(i).OnChannels.Item(Clients(i).OnChannels.Count).Name).IsPrivate)) Then
                          'not private/secret
                          lastchan = Clients(i).OnChannels.Item(Clients(i).OnChannels.Count).Name & " "
                        Else
                          'private/secret
                          lastchan = "* "
                        End If
                    ElseIf Clients(i).OnChannels.Count > 0 And cptr.OnChannels.Count > 0 And Clients(i).IsInvisible Then
                        If Not ((Channels(Clients(i).OnChannels.Item(Clients(i).OnChannels.Count).Name).IsSecret) Or (Channels(Clients(i).OnChannels.Item(Clients(i).OnChannels.Count).Name).IsPrivate)) Then
                          'the channel is not private/secret
                          If cptr.IsOnChan(Clients(i).OnChannels.Item(Clients(i).OnChannels.Count).Name) Then
                            lastchan = Clients(i).OnChannels.Item(Clients(i).OnChannels.Count).Name & " "
                          Else
                            lastchan = "* "
                          End If
                        Else
                          'the channel is private/secret
                          If cptr.IsOnChan(Clients(i).OnChannels.Item(Clients(i).OnChannels.Count).Name) Then
                            lastchan = Clients(i).OnChannels.Item(Clients(i).OnChannels.Count).Name & " "
                          Else
                            lastchan = "* "
                          End If
                        End If
                    ElseIf Channels(Clients(i).OnChannels.Item(Clients(i).OnChannels.Count).Name).IsSecret Then
                        'if the channel is secret, only show it in a /who if the user is on the channel
                        If cptr.IsOnChan(Clients(i).OnChannels.Item(Clients(i).OnChannels.Count).Name) Then
                          lastchan = Clients(i).OnChannels.Item(Clients(i).OnChannels.Count).Name & " "
                        Else
                          lastchan = "* "
                        End If
                    ElseIf Channels(Clients(i).OnChannels.Item(Clients(i).OnChannels.Count).Name).IsPrivate Then
                        'same thing with private
                        If cptr.IsOnChan(Clients(i).OnChannels.Item(Clients(i).OnChannels.Count).Name) Then
                          lastchan = Clients(i).OnChannels.Item(Clients(i).OnChannels.Count).Name & " "
                        Else
                          lastchan = "* "
                        End If
                    Else
                        lastchan = "* "
                    End If
                    If Len(Clients(i).AwayMsg) > 0 Then
                      ExtraInfo = "G"
                    Else
                      ExtraInfo = "H"
                    End If
                    If Clients(i).IsGlobOperator Or Clients(i).IsLocOperator Then ExtraInfo = ExtraInfo & "*"
                    If Clients(i).IsNetAdmin Then ExtraInfo = ExtraInfo & "A"
                    If OperOnly = True Then
                      If Not (Clients(i).IsGlobOperator Or Clients(i).IsLocOperator) Then
                        GoTo SkipUser
                      End If
                    End If
                    If Len(lastchan) = 0 Then lastchan = "* "
                    SendWsock cptr.index, "352 " & cptr.Nick & " " & lastchan & Clients(i).User & " " & Clients(i).Host & " " & ServerName & " " & Clients(i).Nick & " " & ExtraInfo, ":" & Clients(i).Hops & " " & Clients(i).Name
                    ret = ret + 1
SkipUser:
                End If
            Next i
        End If
    End If
    SendWsock cptr.index, SPrefix & " " & 315 & " " & cptr.Nick & " " & parv(0) & " :End of /WHO list.", vbNullString, , True
End If
End Function

'/*
'** m_whois
'**  parv[0] = sender prefix
'**  parv[1] = nickname masklist
'*/
Public Function m_whois(cptr As clsClient, sptr As clsClient, parv$()) As Long
#If Debugging = 1 Then
    SendSvrMsg "WHOIS called! (" & cptr.Nick & ")"
#End If
Dim A$(), i&, c As clsClient
If cptr.AccessLevel = 4 Then
    Set c = GetServer(parv(1))
    If c Is Nothing Then Exit Function
    If c.ServerName = ServerName Then
        SendWsock cptr.index, GlobUsers(parv(0)).GetWhois(sptr.Nick), "", , True
    Else
        SendWsock c.FromLink.index, "WHOIS " & parv(0), ":" & parv(1), sptr.Nick
    End If
Else
  If Len(parv(0)) = 0 Then  'if no nick is given, complain -Dill
    SendWsock cptr.index, ERR_NONICKNAMEGIVEN & " " & cptr.Nick, TranslateCode(ERR_NONICKNAMEGIVEN, , , "WHOIS")
    Exit Function
  End If
  If UBound(parv) = 0 Then
    If InStr(1, parv(0), "*") Then
      If Not (cptr.IsLocOperator Or cptr.IsGlobOperator) Then 'can't /whois * unless ircop
        SendWsock cptr.index, ERR_NOPRIVILEGES & " " & cptr.Nick, TranslateCode(ERR_NOPRIVILEGES)
        Exit Function
      Else
        'wildcard
        Dim Umask$, Target() As clsClient, x As Long
        Umask = ":" & CreateMask(CStr(parv(0)))
        Target = GlobUsers.Values
        For x = LBound(Target) To UBound(Target)
          If Target(x).Prefix Like Umask Then
            Target(x).WhoisAccessLevel = cptr.AccessLevel
            Target(x).WhoisIRCX = cptr.IsIRCX
            SendWsock cptr.index, Target(x).GetWhois(cptr.Nick), vbNullString, , True
          End If
        Next x
        SendWsock cptr.index, RPL_ENDOFWHOIS & " " & cptr.Nick & " " & parv(0), ":End of WHOIS list"
      End If
    Else
      A = Split(parv(0), ",") 'in case we have multiple queries -Dill
      'return results for all queries -Dill
      For i = LBound(A) To UBound(A)
        If Not Len(A(i)) = 0 Then
          Set c = GlobUsers(A(i))
          If c Is Nothing Then
            SendWsock cptr.index, ERR_NOSUCHNICK, cptr.Nick & " " & TranslateCode(ERR_NOSUCHNICK, A(i))
          Else
            c.WhoisAccessLevel = cptr.AccessLevel
            c.WhoisIRCX = cptr.IsIRCX
            #If Debugging = 1 Then
              SendSvrMsg "getting whois for " & c.Nick & "; host: " & c.RealHost
            #End If
            SendWsock cptr.index, c.GetWhois(cptr.Nick), vbNullString, , True
          End If
        End If
      Next i
      'after all query results have been sent, send 'end of whois' message -Dill
      SendWsock cptr.index, RPL_ENDOFWHOIS & " " & cptr.Nick & " " & parv(0), ":End of WHOIS list"
    End If
  Else
    If StrComp(parv(0), parv(1), vbTextCompare) <> 0 Then
        Set c = GetServer(parv(1))
        If c Is Nothing Then
            SendWsock cptr.index, ERR_NOSUCHSERVER & " " & cptr.Nick, TranslateCode(ERR_NOSUCHSERVER, parv(1))
            Exit Function
        End If
        SendWsock c.FromLink.index, "WHOIS " & parv(0), vbNullString, ":" & cptr.Nick
    Else
        If c.Hops > 0 Then
            SendWsock c.FromLink.index, "WHOIS " & parv(0), vbNullString, ":" & cptr.Nick
        Else
            c.WhoisAccessLevel = cptr.AccessLevel
            c.WhoisIRCX = cptr.IsIRCX
            SendWsock cptr.index, c.GetWhois(cptr.Nick), vbNullString, , True
        End If
    End If
  End If
End If
End Function
Public Function FilterReserved(strText As String) As String
'this function filters out reserved characters
'because things like the USER command relies on
'this function, we can't return errors (I don't think
'that USER even has an error for a bad username).
'we replace here because it's the easiest way

Dim t As String
t = strText
t = Replace(t, "!", "")
t = Replace(t, "@", "")
t = Replace(t, "~", "")
t = Replace(t, ".", "")
t = Replace(t, "+", "")
t = Replace(t, "\", "")
t = Replace(t, "/", "")
t = Replace(t, Chr(34), "") 'quote
t = Replace(t, Chr(3), "") 'color (don't want colors in /who)
t = Replace(t, Chr(2), "") 'bold
t = Replace(t, Chr(1), "") 'ctcp
t = Replace(t, Chr(15), "") 'stop formatting symbol (ctrl-O in mIRC)
t = Replace(t, Chr(22), "") 'inverse
FilterReserved = t
End Function
'/*
'** m_user
'**  parv[0] = sender prefix
'**  parv[1] = username (login name, account)
'**  parv[2] = client host name (used only from other servers)
'**  parv[3] = server host name (used only from other servers)
'**  parv[4] = users real name info
'**  parv[5] = users mode (is only used internally by the server,
'**        NULL otherwise)
'*/
Public Function m_user(cptr As clsClient, sptr As clsClient, parv$()) As Long
#If Debugging = 1 Then
    SendSvrMsg "USER called! (" & cptr.Nick & ")"
#End If
Dim ShowNick As String
Dim tmpPass As String
If Len(cptr.Nick) = 0 Then
  ShowNick = "Anonymous"
Else
  ShowNick = cptr.Nick
End If
  If Len(parv(0)) = 0 Then
    SendWsock cptr.index, ERR_NEEDMOREPARAMS & " " & ShowNick, TranslateCode(ERR_NEEDMOREPARAMS, , , "USER")
    Exit Function
  End If
  If UBound(parv) = 0 Then
    SendWsock cptr.index, ERR_NEEDMOREPARAMS & " " & ShowNick, TranslateCode(ERR_NEEDMOREPARAMS, , , "USER")
    Exit Function
  End If
  If Len(cptr.User) <> 0 Then
    SendWsock cptr.index, ERR_ALREADYREGISTRED & " " & ShowNick, TranslateCode(ERR_ALREADYREGISTRED)
    Exit Function
  End If
  Dim Ident$, pdat$, i&, x&, z&, allusers() As clsClient
  'removed the IsValidUserString crap
  With cptr
    .User = FilterReserved(parv(0)) 'filter out illegal and legal annoying chars
    If NickLen > 0 Then
      .User = Left$(.User, NickLen)
    End If
    If UBound(parv) >= 3 Then
      .Name = parv(3)
    Else
      .Name = ""
    End If
    If DoKLine(cptr) Then
        cptr.IsKilled = True
        cptr.SendQ = vbNullString
        'klines can only be engaged in m_user before a user registers
        KillStruct cptr.Nick, , False, cptr.IP
        IrcStat.UnknownConnections = IrcStat.UnknownConnections - 1
        Exit Function
    End If
    If Len(ILine(cptr.IIndex).Pass) > 0 Then
      If .PassOK = False Then
          If MD5Crypt = True Then
            tmpPass = oMD5.MD5(cptr.Password)
          Else
            tmpPass = cptr.Password
          End If
          If StrComp(tmpPass, ILine(cptr.IIndex).Pass) <> 0 Then
            'bad password, get out of here -zg
            m_error cptr, "Closing Link: (Bad Password)"
            KillStruct cptr.Nick, , False, cptr.IP
            Exit Function
          Else
            'the password is valid, let them keep rolling on... -zg
            cptr.PassOK = True
          End If
      End If
    Else
      'there is no password, assume password is okay -zg
      cptr.PassOK = True
    End If
    If .IP = MonitorIP And Die = True Then
        'rehash the server
        Rehash vbNullString
    End If
    If Die = True Then
        'For x = 1 To .OnChannels.Count
        '    SendToChan .OnChannels.Item(x), .Prefix & " AutoKilled: Server Misconfigured", vbNullString
        'Next x
        SendToServer "QUIT :AutoKilled: Server Misconfigured [see ircx.conf]", .Nick
        SendWsock .index, "KILL " & .Nick, ":AutoKilled: Server Misconfigured [see ircx.conf]", .Prefix
        m_error cptr, "Closing Link: (AutoKilled: Server Misconfigured [see ircx.conf])"
        ErrorMsg "The server is misconfigured. Please see ircx.conf."
        .IsKilled = True
        KillStruct .Nick, , False, .IP
        Exit Function
    End If
    If OfflineMode = True Then
        If Len(OfflineMessage) = 0 Then
            'For x = 1 To .OnChannels.Count
            '    SendToChan .OnChannels.Item(x), .Prefix & " AutoKilled: Server In Offline Mode", vbNullString
            'Next x
            SendToServer "QUIT :AutoKilled: Server In Offline Mode", .Nick
            SendWsock .index, "KILL " & .Nick, ":AutoKilled: Server In Offline Mode", .Prefix
            m_error cptr, "Closing Link: (AutoKilled: Server In Offline Mode)"
            .IsKilled = True
            KillStruct .Nick, , False, .IP
            Exit Function
        Else
            For x = 1 To .OnChannels.Count
                SendToChan .OnChannels.Item(x), .Prefix & " AutoKilled: " & OfflineMessage, vbNullString
            Next x
            SendToServer "QUIT :AutoKilled: " & OfflineMessage, .Nick
            SendWsock .index, "KILL " & .Nick, ":AutoKilled: " & OfflineMessage, .Prefix
            m_error cptr, "Closing Link: (AutoKilled: " & OfflineMessage & ")"
            .IsKilled = True
            KillStruct .Nick, , False, .IP
            Exit Function
        End If
    End If
    
    If Len(.Nick) = 0 Then Exit Function
    If Not cptr.SentLogonNotices Then
      pdat = GetRand
      SendWsock cptr.index, "NOTICE AUTH", ":*** If you experience problems while connecting please email the admin (" & mod_list.AdminEmail & ") about it and include the server you tried to connect to (" & ServerName & ")."
      SendWsock cptr.index, "NOTICE AUTH", ":*** If you experience problems due to PING timeouts, type '/QUOTE PONG :" & pdat & "' or '/RAW PONG :" & pdat & "' now."
      If Not Len(CustomNotice) = 0 Then 'moved so user will always see notice -AW
          SendWsock cptr.index, "NOTICE AUTH", ":*** " & CustomNotice
      End If
      SendWsock cptr.index, "PING " & pdat, vbNullString, , True
      IrcStat.UnknownConnections = IrcStat.UnknownConnections - 1
      cptr.SentLogonNotices = True
    End If
  End With
End Function

'/*
'** m_quit
'**  parv[0] = sender prefix
'**  parv[1] = comment
'*/
Public Function m_quit(cptr As clsClient, sptr As clsClient, parv$()) As Long
#If Debugging = 1 Then
    SendSvrMsg "QUIT called! (" & cptr.Nick & ")"
#End If
On Error Resume Next
If cptr.AccessLevel = 4 Then
    Dim i As Long
    For i = 1 To sptr.OnChannels.Count
      'if the channel is auditorium, only send the quit to everyone
      'if everyone saw this person to begin with
      If sptr.OnChannels.Item(i).IsAuditorium Then
          If ((sptr.OnChannels.Item(i).Member.Item(sptr.Nick).IsOp) Or (sptr.OnChannels.Item(i).Member.Item(sptr.Nick).IsOwner)) Then
            SendToChan sptr.OnChannels.Item(i), sptr.Prefix & " QUIT :" & parv(0), vbNullString
          Else
            'the person wasn't a host/owner, so only the hosts/owners know about him/her
            SendToChanOps sptr.OnChannels.Item(i), sptr.Prefix & " QUIT :" & parv(0), vbNullString
          End If
      Else
          SendToChan sptr.OnChannels.Item(i), sptr.Prefix & " QUIT :" & parv(0), vbNullString
      End If
      'SendToChan sptr.OnChannels.Item(I), sptr.Prefix & " QUIT :" & parv(0), vbNullString
    Next i
    KillStruct sptr.Nick
    SendToServer_ButOne "QUIT " & sptr.Nick & " :" & parv(0), cptr.ServerName, sptr.Nick
    GenerateEvent "USER", "QUIT", Replace(sptr.Prefix, ":", ""), Replace(sptr.Prefix, ":", "") & " :" & parv(0)
    Set sptr = Nothing
Else
    On Error Resume Next
    Dim x() As clsChanMember, Chan As clsChannel, Msg As String, y&
    Dim QuitText As String
    If Len(parv(0)) = 0 Then QuitText = "Client Exited"
    If QuitLen > 0 Then
        parv(0) = Mid$(parv(0), 1, QuitLen)
    End If
    'If you specified a message, it goes:
    '*** Nick has quit ("reason here")
    'like on freenode :)
    If Len(parv(0)) > 0 Then QuitText = """" & parv(0) & """"
    Msg = cptr.Prefix & " QUIT :" & QuitText & vbCrLf
    If cptr.OnChannels.Count > 0 Then
      For y = 1 To cptr.OnChannels.Count
          x = cptr.OnChannels.Item(y).Member.Values
          
          'if the channel is auditorium, only send the quit to everyone
          'if everyone saw this person to begin with
          If cptr.OnChannels.Item(y).IsAuditorium Then
              If ((cptr.OnChannels.Item(y).Member.Item(cptr.Nick).IsOp) Or (cptr.OnChannels.Item(y).Member.Item(cptr.Nick).IsOwner)) Then
                SendToChan cptr.OnChannels.Item(y), Replace(Msg, vbCrLf, vbNullString), 0   'Notify all channelmembers -Dill
              Else
                'the person wasn't a host/owner, so only the hosts/owners know about him/her
                SendToChanOps cptr.OnChannels.Item(y), Replace(Msg, vbCrLf, vbNullString), 0   'Notify all ops
              End If
          Else
              SendToChan cptr.OnChannels.Item(y), Replace(Msg, vbCrLf, vbNullString), 0   'Notify all channelmembers -Dill
          End If
          
          cptr.OnChannels.Item(y).Member.Remove cptr.Nick
      Next
    End If
    m_error cptr, "Closing Link: (" & QuitText & ")" 'confirm the quit and disconnect the client -Dill
    If Len(cptr.Nick) > 0 Then
      'if there's no nick, don't waste other server's time
      '(we haven't yet sent them NICK)
      SendToServer "QUIT " & cptr.Nick & " :" & QuitText, cptr.Nick
    End If
    GenerateEvent "USER", "QUIT", Replace(cptr.Prefix, ":", ""), Replace(cptr.Prefix, ":", "") & " :" & QuitText
    GenerateEvent "USER", "LOGOFF", Replace(cptr.Prefix, ":", ""), Replace(cptr.Prefix, ":", "")
    GenerateEvent "SOCKET", "CLOSE", "*!*@*", cptr.IP & ":" & cptr.RemotePort & " " & ServerLocalAddr & ":" & cptr.LocalPort
    If cptr.HasRegistered = False Then
      KillStruct cptr.Nick, , False, cptr.IP
      IrcStat.UnknownConnections = IrcStat.UnknownConnections - 1
    Else
      KillStruct cptr.Nick
    End If
    Set cptr = Nothing
End If
End Function
'/*
'** m_kill
'**  parv[0] = sender prefix
'**  parv[1] = kill victim
'**  parv[2] = kill path
'*/
Public Function m_kill(cptr As clsClient, sptr As clsClient, parv$(), Optional HideQuotes As Boolean = False) As Long
#If Debugging = 1 Then
   SendSvrMsg "KILL called! (" & cptr.Nick & ")"
#End If
Dim y&, User As clsClient, i&, x&, allusers() As clsClient, sender$, QMsg$, Killed() As clsClient
On Error Resume Next
If cptr.AccessLevel = 4 Then
   Set User = GlobUsers(parv(0))
   If User.AccessLevel = 4 Then
       SendWsock cptr.index, ERR_CANTKILLSERVER & " " & cptr.Nick, TranslateCode(ERR_CANTKILLSERVER)
       Exit Function
   End If
   If User Is Nothing Then
       SendWsock cptr.index, ERR_NOSUCHNICK, cptr.Nick & " " & TranslateCode(ERR_NOSUCHNICK, parv(0))
       Exit Function
   End If '// we don't want to even attempt killing a nick that doesn't exist -ziggy
   If Len(sptr.Nick) = 0 Then
       sender = cptr.ServerName
   Else
       sender = sptr.Nick
   End If
   
   SendSvrMsg "Recieved KILL message for: " & Replace(User.Prefix, ":", "") & " from " & sender & " (" & parv(1) & ")"
   For x = 1 To User.OnChannels.Count
       SendToChan User.OnChannels.Item(x), User.Prefix & " QUIT :Killed by " & sender & _
       " (" & parv(1) & ")", vbNullString
   Next x
   If User.Hops = 0 Then
       SendWsock User.index, "KILL " & User.Nick, ":Killed by " & sender & " (" & parv(1) & ")", sender '// include reason -ziggy
       m_error User, "Closing Link: (Killed by " & sender & " (" & parv(1) & "))" '// this automatically disconnects the user -ziggy
   End If
   GenerateEvent "USER", "KILL", Replace(cptr.Prefix, ":", ""), Replace(cptr.Prefix, ":", "") & " :" & parv(1)
   GenerateEvent "USER", "LOGOFF", Replace(cptr.Prefix, ":", ""), Replace(cptr.Prefix, ":", "")
   GenerateEvent "SOCKET", "CLOSE", "*!*@*", cptr.IP & ":" & cptr.RemotePort & " " & ServerLocalAddr & ":" & cptr.LocalPort
   KillStruct User.Nick '// User.Nick is the right capitalization; parv(0) isn't -ziggy
   User.IsKilled = True '// this should be set so the other parts of the program know we killed it -ziggy
   SendToServer_ButOne "KILL " & User.Nick & " :" & parv(1), cptr.ServerName, sender
   Set User = Nothing
Else
   If Len(parv(0)) = 0 Then
       SendWsock cptr.index, ERR_NEEDMOREPARAMS & " " & cptr.Nick, TranslateCode(ERR_NEEDMOREPARAMS, , , "KILL")
       Exit Function
   End If
   If UBound(parv) = 0 Then
       SendWsock cptr.index, ERR_NEEDMOREPARAMS & " " & cptr.Nick, TranslateCode(ERR_NEEDMOREPARAMS, , , "KILL")
       Exit Function
   End If
   '// global kills (yuck) -ziggy
   If Not HideQuotes Then parv(1) = """" & parv(1) & """"
   If InStr(1, parv(0), "*") > 0 Then
       If Not cptr.CanGlobKill Then
           SendWsock cptr.index, ERR_NOPRIVILEGES & " " & cptr.Nick, TranslateCode(ERR_NOPRIVILEGES)
           Exit Function
       End If
       QMsg = " QUIT :Killed by " & cptr.Nick & " (" & parv(1) & ")"
       SendSvrMsg "Recieved KILL message for " & parv(0) & " from " & cptr.Nick & " (" & parv(1) & ")" '// include reason -ziggy
       parv(0) = CreateMask(parv(0))
       allusers = GlobUsers.Values
       For i = LBound(allusers) To UBound(allusers)
           '// now THIS could be a major problem
           '// we need to make sure that the AccessLevel is 4, and the user wanted to kill the server in the first place
           '// since this would trigger if a server was connected -ziggy
           If allusers(i).AccessLevel = 4 And UCase$(allusers(i).Prefix) Like UCase$(":" & parv(0)) Then '// casing does not matter -ziggy
               SendWsock cptr.index, ERR_CANTKILLSERVER & " " & cptr.Nick, TranslateCode(ERR_CANTKILLSERVER)
               Exit Function
           End If
           If UCase$(allusers(i).Prefix) Like UCase$(":" & parv(0)) Then '// casing does not matter -ziggy
             For x = 1 To allusers(i).OnChannels.Count
               SendToChan allusers(i).OnChannels.Item(x), allusers(i).Prefix & QMsg, vbNullString
             Next x
             If allusers(i).Hops > 0 Then
               SendWsock allusers(i).FromLink.index, "KILL " & allusers(i).Nick, ":Killed by " & cptr.Nick & " (" & parv(1) & ")", cptr.Prefix
             Else
               SendWsock allusers(i).index, "KILL " & allusers(i).Nick, ":Killed by " & cptr.Nick & " (" & parv(1) & ")", cptr.Prefix
               m_error allusers(i), "Closing Link: (Killed by " & Replace(cptr.Prefix, ":", "") & " (" & parv(1) & "))" '// send reason -ziggy
             End If
             
             GenerateEvent "USER", "KILL", Replace(allusers(i).Prefix, ":", ""), Replace(allusers(i).Prefix, ":", "") & " :" & parv(1)
             GenerateEvent "USER", "LOGOFF", Replace(allusers(i).Prefix, ":", ""), Replace(allusers(i).Prefix, ":", "")
             GenerateEvent "SOCKET", "CLOSE", "*!*@*", allusers(i).IP & ":" & allusers(i).RemotePort & " " & ServerLocalAddr & ":" & allusers(i).LocalPort
             KillStruct allusers(i).Nick, enmTypeClient
             allusers(i).IsKilled = True
             Set allusers(i) = Nothing
           End If
       Next i
       SendToServer "QUIT :Killed by " & cptr.Nick & " (" & parv(1) & ")", allusers(i).Nick
   Else '// not global
       Set User = GlobUsers(parv(0))
       If User Is Nothing Then
           SendWsock cptr.index, ERR_NOSUCHNICK, cptr.Nick & " " & TranslateCode(ERR_NOSUCHNICK, parv(0))
           Exit Function
       End If
       If User.AccessLevel = 4 Then
           SendWsock cptr.index, ERR_CANTKILLSERVER & " " & cptr.Nick, TranslateCode(ERR_CANTKILLSERVER)
           Exit Function
       End If
       If User.Hops > 0 Then
           If Not cptr.CanGlobKill Then
               SendWsock cptr.index, ERR_NOPRIVILEGES & " " & cptr.Nick, TranslateCode(ERR_NOPRIVILEGES)
               Exit Function
           End If
           SendWsock User.FromLink.index, "KILL " & User.Nick, ":Killed by " & cptr.Nick & " (" & parv(1) & ")", cptr.Prefix
           For x = 1 To User.OnChannels.Count
               SendToChan User.OnChannels.Item(x), User.Prefix & " QUIT :Killed by " & cptr.Nick & " (" & parv(1) & ")", vbNullString
           Next x
           SendSvrMsg "Recieved KILL message for " & User.Nick & " from " & cptr.Nick & " (" & parv(1) & ")" '// include reason -ziggy
           SendToServer "QUIT :Killed by " & cptr.Nick & " (" & parv(1) & ")", User.Nick
           GenerateEvent "USER", "KILL", Replace(User.Prefix, ":", ""), Replace(User.Prefix, ":", "") & " :" & parv(1)
           GenerateEvent "USER", "LOGOFF", Replace(User.Prefix, ":", ""), Replace(User.Prefix, ":", "")
           GenerateEvent "SOCKET", "CLOSE", "*!*@*", User.IP & ":" & User.RemotePort & " " & ServerLocalAddr & ":" & User.LocalPort
           KillStruct User.Nick
       Else
           If Not cptr.CanLocKill Then
               SendWsock cptr.index, ERR_NOPRIVILEGES & " " & cptr.Nick, TranslateCode(ERR_NOPRIVILEGES)
               Exit Function
           End If
           For x = 1 To User.OnChannels.Count
               SendToChan User.OnChannels.Item(x), User.Prefix & " QUIT :Killed by " & cptr.Nick & " (" & parv(1) & ")", vbNullString
           Next x
           SendSvrMsg "Recieved KILL message for " & User.Nick & " from " & cptr.Nick & " (" & parv(1) & ")" '// include reason -ziggy
           SendToServer "QUIT :Killed by " & cptr.Nick & " (" & parv(1) & ")", User.Nick
           SendWsock User.index, "KILL " & User.Nick, ":Killed by " & cptr.Nick & " (" & parv(1) & ")", cptr.Prefix
           GenerateEvent "USER", "KILL", Replace(User.Prefix, ":", ""), Replace(User.Prefix, ":", "") & " :" & parv(1)
           GenerateEvent "USER", "LOGOFF", Replace(User.Prefix, ":", ""), Replace(User.Prefix, ":", "")
           GenerateEvent "SOCKET", "CLOSE", "*!*@*", User.IP & ":" & User.RemotePort & " " & ServerLocalAddr & ":" & User.LocalPort
           m_error User, "Closing Link: (Killed by " & Replace(cptr.Prefix, ":", "") & " (" & parv(1) & "))" '// m_error disconnects the user -ziggy
           User.IsKilled = True
           KillStruct User.Nick
       End If
   End If
End If
End Function

'/***********************************************************************
' * m_away() - Added 14 Dec 1988 by jto.
' *      Not currently really working, I don't like this
' *      call at all...
' *
' *      ...trying to make it work. I don't like it either,
' *        but perhaps it's worth the load it causes to net.
' *        This requires flooding of the whole net like NICK,
' *        USER, MODE, etc messages...  --msa
' ***********************************************************************/
'
'/*
'** m_away
'**  parv[0] = sender prefix
'**  parv[1] = away message
'*/
Public Function m_away(cptr As clsClient, sptr As clsClient, parv$()) As Long
#If Debugging = 1 Then
    SendSvrMsg "AWAY called! (" & cptr.Nick & ")"
#End If
If cptr.AccessLevel = 4 Then
  If Len(sptr.AwayMsg) > 0 Then
    sptr.AwayMsg = vbNullString
  Else
    cptr.AwayMsg = parv(0)
  End If
  SendToServer_ButOne "AWAY :" & parv(0), cptr.ServerName, sptr.Nick
Else
  If Len(parv(0)) > 0 Then
    cptr.AwayMsg = parv(0)
    SendWsock cptr.index, RPL_NOWAWAY & " " & cptr.Nick, ":You have been marked as being away"
  Else
    cptr.AwayMsg = vbNullString
    SendWsock cptr.index, RPL_UNAWAY & " " & cptr.Nick, ":You are no longer marked as being away"
  End If
  SendToServer "AWAY :" & parv(0), cptr.Nick
End If
End Function

'/*
'** m_ping
'**  parv[0] = sender prefix
'**  parv[1] = origin
'**  parv[2] = destination
'*/
Public Function m_ping(cptr As clsClient, sptr As clsClient, parv$()) As Long
If cptr.AccessLevel = 4 Then
'RFC1459 says to ignore PINGs from servers
'but we'll set the lastaction ;)
cptr.LastAction = UnixTime
sptr.LastAction = UnixTime
Else
  ':server PONG server :text
  If Len(parv(0)) = 0 Then
    SendWsock cptr.index, "PONG " & ServerName, ""
  Else
    If parv(0) = SPrefix Then
      SendWsock cptr.index, "PONG " & ServerName, ""
    Else
      SendWsock cptr.index, "PONG " & ServerName & " :" & parv(0), ""
    End If
  End If
End If
End Function

'/*
'** m_oper
'**  parv[0] = sender prefix
'**  parv[1] = oper name
'**  parv[2] = oper password
'*/
Public Function m_oper(cptr As clsClient, sptr As clsClient, parv$()) As Long
#If Debugging = 1 Then
    SendSvrMsg "OPER called! (" & cptr.Nick & ")"
#End If
If cptr.AccessLevel = 4 Then
Else
    If Len(parv(0)) = 0 Then
        SendWsock cptr.index, ERR_NEEDMOREPARAMS & " " & cptr.Nick, TranslateCode(ERR_NEEDMOREPARAMS, , , "OPER")
        Exit Function
    End If
    If UBound(parv) = 0 Then
        SendWsock cptr.index, ERR_NEEDMOREPARAMS & " " & cptr.Nick, TranslateCode(ERR_NEEDMOREPARAMS, , , "OPER")
        Exit Function
    End If
    #If SendMessageOnInvalidLogin = 0 Then
        Call DoOLine(cptr, parv(1), parv(0))
    #Else
        If Not DoOLine(cptr, parv(1), parv(0)) Then SendSvrMsg "IRC Operator authentication failed for: " & Replace(cptr.Prefix, ":", "")
    #End If
End If
End Function

'/***************************************************************************
' * m_pass() - Added Sat, 4 March 1989
' *                       - did VB6 exist in 1989? -z
' ***************************************************************************/
'
'/*
'** m_pass
'**  parv[0] = sender prefix
'**  parv[1] = password
'**  parv[2] = protocol & server versions (server only)
'**  parv[3] = server id & options (server only)
'**  parv[4] = (optional) link options (server only)
'*/
Public Function m_pass(cptr As clsClient, sptr As clsClient, parv$()) As Long
#If Debugging = 1 Then
    SendSvrMsg "PASS called! (" & cptr.Nick & ") (" & sptr.Nick & ")"
#End If
Dim ShowNick As String
If Len(cptr.Nick) = 0 Then
  ShowNick = "Anonymous"
Else
  ShowNick = cptr.Nick
End If

If Len(parv(0)) = 0 Then
    SendWsock cptr.index, ERR_NEEDMOREPARAMS & " " & ShowNick, TranslateCode(ERR_NEEDMOREPARAMS, , , "PASS")
    Exit Function
End If

'If cptr.PassOK = True Then m_pass = 1: Exit Function

'for password-protected servers,
'and the link matches the protected I: line,
'links will need to have a special I:
'line for themselves, otherwise
'they'll have two different passwords
'which is a Bad Thing™
#If Debugging = 1 Then
  SendSvrMsg "IIndex: '" & cptr.IIndex & "'; Pass: '" & ILine(cptr.IIndex).Pass & "'"
#End If

'// set the password, will be checked in USER or SERVER, depending on what command is sent
cptr.Password = parv(0)

'If Len(Trim$(ILine(cptr.IIndex).Pass)) <> 0 Then
'  Dim tmpPass As String
'  If MD5Crypt = True Then
'     tmpPass = oMD5.MD5(parv(0))
'  Else
'     tmpPass = parv(0)
'  End If
'
'  If StrComp(tmpPass, ILine(cptr.IIndex).Pass) = 0 Then
'    m_pass = 1
'    cptr.PassOK = True
'    Exit Function
'  Else
'    m_pass = -1
'    cptr.PassOK = False
'    Exit Function
'  End If
'End If
'
'so they didn't get caught by the I: line?
'did their password match a L: line?
'#If Debugging = 1 Then
'  SendSvrMsg "*** trying as server"
'#End If
'
'If Not cptr.NLined Then
'    #If Debugging = 1 Then
'      SendSvrMsg "*** not NLined"
'    #End If
'    If DoNLine(cptr) Then
'        #If Debugging = 1 Then
'          SendSvrMsg "DoNLine, checking password..."
'        #End If
'        If StrComp(parv(0), ILine(cptr.IIndex).Pass) = 0 And Len(ILine(cptr.IIndex).Pass) <> 0 Then
'            #If Debugging = 1 Then
'              SendSvrMsg "DoNLine, Password OK!"
'            #End If
'            m_pass = 1
'            cptr.PassOK = True
'        Else
'            #If Debugging = 1 Then
'              SendSvrMsg "DoNLine, Password bad."
'            #End If
'            m_pass = -1
'            cptr.PassOK = False
'            cptr.NLined = False
'            cptr.AccessLevel = 1
'        End If
'    Else
'        If StrComp(parv(0), NLine(cptr.IIndex).Pass) = 0 Then
'            #If Debugging = 1 Then
'              SendSvrMsg "Not DoNLine, Password OK!"
'            #End If
'            m_pass = 1
'            cptr.PassOK = True
'            cptr.NLined = True
'        Else
'            #If Debugging = 1 Then
'              SendSvrMsg "Not DoNLine, Password bad"
'            #End If
'            cptr.AccessLevel = 1
'            m_error cptr, "Closing Link: (Bad Password)"
'            KillStruct cptr.Nick, , False
'            m_pass = -1
'            cptr.PassOK = False
'            cptr.NLined = False
'        End If
'    End If
'End If
End Function

'/*
' * m_userhost added by Darren Reed 13/8/91 to aid clients and reduce
' * the need for complicated requests like WHOIS. It returns user/host
' * information only (no spurious AWAY labels or channels).
' */
Public Function m_userhost(cptr As clsClient, sptr As clsClient, parv$()) As Long
#If Debugging = 1 Then
    SendSvrMsg "USERHOST called! (" & cptr.Nick & ")"
#End If
Dim i&, User As clsClient, ret$
If cptr.AccessLevel = 4 Then
Else
  If Len(parv(0)) = 0 Then
    SendWsock cptr.index, ERR_NEEDMOREPARAMS & " " & cptr.Nick, TranslateCode(ERR_NEEDMOREPARAMS, , , "USERHOST")
    Exit Function
  End If
  For i = 0 To UBound(parv)
    Set User = GlobUsers(parv(i))
    If Not User Is Nothing Then ret = ret & User.Nick & IIf((User.IsLocOperator Or User.IsGlobOperator), "*", vbNullString) & "=" & IIf(Len(User.AwayMsg) > 0, "-", "+") & User.User & "@" & User.Host & " "
    If i = 4 Then Exit For 'alas, off by one!
  Next i
  SendWsock cptr.index, RPL_USERHOST & " " & cptr.Nick, ":" & Trim$(ret)
End If
End Function

'/*
' * m_ison added by Darren Reed 13/8/91 to act as an efficent user indicator
' * with respect to cpu/bandwidth used. Implemented for NOTIFY feature in
' * clients. Designed to reduce number of whois requests. Can process
' * nicknames in batches as long as the maximum buffer length.
'                               ^^^^^
'  "with respect to cpu used", eh? this code won't do much good with alot clients -Dill
' *
' * format:
' * ISON :nicklist
' */
Public Function m_ison(cptr As clsClient, sptr As clsClient, parv$()) As Long
#If Debugging = 1 Then
    SendSvrMsg "ISON called! (" & cptr.Nick & ")"
#End If
Dim i&, ret$, CurUser$
For i = LBound(parv) To UBound(parv)
  CurUser = parv(i)
  If Not GlobUsers(CurUser) Is Nothing Then ret = ret & CurUser & " "
Next i
SendWsock cptr.index, RPL_ISON & " " & cptr.Nick, ":" & Trim$(ret)
End Function

Public Function add_umodes(cptr As clsClient, Modes$) As String
#If Debugging = 1 Then
    SendSvrMsg "add_umodes called! (" & cptr.Nick & ") (" & Modes & ")"
#End If
Dim x&, CurMode$
Dim ModeList As String
Dim ExpandModes As Boolean
ExpandModes = True
ModeList = ""
For x = 1 To Len(Modes)
    CurMode = Mid$(Modes, x, 1)
    If CurMode = "-" Then ExpandModes = False
    Select Case Asc(CurMode)
        Case umServerMsg
            If cptr.IsServerMsg = False Then
              cptr.IsServerMsg = True
              ServerMsg.Add cptr.GUID, cptr
            End If
            ModeList = ModeList & CurMode
        Case umWallOps
            'don't add it twice
            If cptr.GetsWallops = False Then
              cptr.GetsWallops = True
              WallOps.Add cptr.GUID, cptr
            End If
            ModeList = ModeList & CurMode
        Case umLocOper
            If Not cptr.IsLocOperator Then ModeList = ModeList & Chr(umLocOper)
            cptr.IsLocOperator = True
            If ExpandModes = True Then
              If Not cptr.CanLocRoute Then ModeList = ModeList & Chr(umLocRouting)
              cptr.CanLocRoute = True
              If Not cptr.CanRehash Then ModeList = ModeList & Chr(umCanRehash)
              cptr.CanRehash = True
              If Not cptr.CanLocKill Then ModeList = ModeList & Chr(umLocKills)
              cptr.CanLocKill = True
              If Not cptr.CanKline Then ModeList = ModeList & Chr(umCanKline)
              cptr.CanKline = True
              If Not cptr.CanUnkline Then ModeList = ModeList & Chr(umCanUnKline)
              cptr.CanUnkline = True
            End If
        Case umGlobOper
            If Not cptr.IsGlobOperator Then ModeList = ModeList & Chr(umGlobOper)
            cptr.IsGlobOperator = True
            If ExpandModes = True Then
              If Not cptr.IsLocOperator Then ModeList = ModeList & Chr(umLocOper)
              cptr.IsLocOperator = True
              If Not cptr.CanLocRoute Then ModeList = ModeList & Chr(umLocRouting)
              cptr.CanLocRoute = True
              If Not cptr.CanRehash Then ModeList = ModeList & Chr(umCanRehash)
              cptr.CanRehash = True
              If Not cptr.CanLocKill Then ModeList = ModeList & Chr(umLocKills)
              cptr.CanLocKill = True
              If Not cptr.CanKline Then ModeList = ModeList & Chr(umCanKline)
              cptr.CanKline = True
              If Not cptr.CanUnkline Then ModeList = ModeList & Chr(umCanUnKline)
              cptr.CanUnkline = True
              If Not cptr.CanGlobKill Then ModeList = ModeList & Chr(umGlobKills)
              cptr.CanGlobKill = True
              If Not cptr.CanGlobRoute Then ModeList = ModeList & Chr(umGlobRouting)
              cptr.CanGlobRoute = True
              If Not cptr.CanWallop Then ModeList = ModeList & Chr(umCanWallop)
              cptr.CanWallop = True
            End If
        Case umNetAdmin
            If Not cptr.IsNetAdmin Then ModeList = ModeList & Chr(umNetAdmin)
            cptr.IsNetAdmin = True
            If ExpandModes = True Then
              If Not cptr.IsGlobOperator Then ModeList = ModeList & Chr(umGlobOper)
              cptr.IsGlobOperator = True
              If Not cptr.IsLocOperator Then ModeList = ModeList & Chr(umLocOper)
              cptr.IsLocOperator = True
              If Not cptr.CanLocRoute Then ModeList = ModeList & Chr(umLocRouting)
              cptr.CanLocRoute = True
              If Not cptr.CanRehash Then ModeList = ModeList & Chr(umCanRehash)
              cptr.CanRehash = True
              If Not cptr.CanLocKill Then ModeList = ModeList & Chr(umLocKills)
              cptr.CanLocKill = True
              If Not cptr.CanKline Then ModeList = ModeList & Chr(umCanKline)
              cptr.CanKline = True
              If Not cptr.CanUnkline Then ModeList = ModeList & Chr(umCanUnKline)
              cptr.CanUnkline = True
              If Not cptr.CanGlobKill Then ModeList = ModeList & Chr(umGlobKills)
              cptr.CanGlobKill = True
              If Not cptr.CanGlobRoute Then ModeList = ModeList & Chr(umGlobRouting)
              cptr.CanGlobRoute = True
              If Not cptr.CanDie Then ModeList = ModeList & Chr(umCanDie)
              cptr.CanDie = True
              If Not cptr.CanRestart Then ModeList = ModeList & Chr(umCanRestart)
              cptr.CanRestart = True
              If Not cptr.CanWallop Then ModeList = ModeList & Chr(umCanWallop)
              cptr.CanWallop = True
              If Not cptr.CanChange Then ModeList = ModeList & Chr(umCanChange)
              cptr.CanChange = True
            End If
        Case umCanWallop
            cptr.CanWallop = True
            ModeList = ModeList & CurMode
        Case umCanChange
            cptr.CanChange = True
            ModeList = ModeList & CurMode
        Case umInvisible
            cptr.IsInvisible = True
            ModeList = ModeList & CurMode
        Case umHostCloak
            cptr.IsCloaked = True
            ModeList = ModeList & CurMode
        Case umCanRehash
            cptr.CanRehash = True
            ModeList = ModeList & CurMode
        Case umCanRestart
            cptr.CanRestart = True
            ModeList = ModeList & CurMode
        Case umCanDie
            cptr.CanDie = True
            ModeList = ModeList & CurMode
        Case umLocRouting
            cptr.CanLocRoute = True
            ModeList = ModeList & CurMode
        Case umGlobRouting
            cptr.CanGlobRoute = True
            ModeList = ModeList & CurMode
        Case umLocKills
            cptr.CanLocKill = True
            ModeList = ModeList & CurMode
        Case umGlobKills
            cptr.CanGlobKill = True
            ModeList = ModeList & CurMode
        Case umCanKline
            cptr.CanKline = True
            ModeList = ModeList & CurMode
        Case umCanUnKline
            cptr.CanUnkline = True
            ModeList = ModeList & CurMode
        Case umRegistered
            cptr.IsRegistered = True
            ModeList = ModeList & CurMode
        Case umLProtected
            If Not cptr.IsProtected = True Then
                cptr.IsLProtected = True
                ModeList = ModeList & CurMode
            End If
        Case umProtected
            If cptr.IsLProtected = True Then
                cptr.IsLProtected = False
            End If
            cptr.IsProtected = True
            ModeList = ModeList & CurMode
        Case umCanAdd
            cptr.CanAdd = True
            ModeList = ModeList & CurMode
        Case umRemoteAdmin
            cptr.IsRemoteAdmClient = True
            ModeList = ModeList & CurMode
    End Select
Next x
#If Debugging = 1 Then
  SendSvrMsg "ModeList: " & ModeList
#End If
add_umodes = ModeList
End Function

Public Function m_whowas(cptr As clsClient, sptr As clsClient, parv$()) As Long
#If Debugging = 1 Then
    SendSvrMsg "WHOWAS called! (" & cptr.Nick & ")"
#End If
If Len(parv(0)) = 0 Then
    SendWsock cptr.index, ERR_NONICKNAMEGIVEN & " " & cptr.Nick, TranslateCode(ERR_NONICKNAMEGIVEN, , , "WHOWAS")
    Exit Function
End If
Dim ww As typWhoWas, User$(), i&
User = Split(parv(0), ",")
For i = LBound(User) To UBound(User)
    ww = modWhoWasHashTable.Item(User(i))
    If Len(ww.Nick) > 0 Then
        SendWsock cptr.index, 314 & " " & cptr.Nick & " " & ww.Nick & " " & ww.User & " " & ww.Host & " *", ":" & ww.Name
        SendWsock cptr.index, 312 & " " & cptr.Nick & " " & ww.Nick & " " & ww.Server, ":" & ww.SignOn
    Else
        SendWsock cptr.index, 406 & " " & cptr.Nick & " " & User(i), ":There was no such nickname"
    End If
Next i
SendWsock cptr.index, 369 & " " & cptr.Nick & " " & parv(0), ":End of WHOWAS"
End Function

Public Function m_nickserv(cptr As clsClient, sptr As clsClient, NickServName As String, parv$()) As Long
Set sptr = GlobUsers(NickServName)
If sptr Is Nothing Then
    SendWsock cptr.index, ERR_SERVICESDOWN & " " & cptr.Nick & " NS", ":Services are currently down. Please try again later."
    Exit Function
End If
SendWsock sptr.FromLink.index, "PRIVMSG " & NickServName, ":" & Join(parv), ":" & cptr.Nick
End Function

Public Function m_chanserv(cptr As clsClient, sptr As clsClient, ChanServName As String, parv$()) As Long
Set sptr = GlobUsers(ChanServName)
If sptr Is Nothing Then
    SendWsock cptr.index, ERR_SERVICESDOWN & " " & cptr.Nick & " CS", ":Services are currently down. Please try again later."
    Exit Function
End If
SendWsock sptr.FromLink.index, "PRIVMSG " & ChanServName, ":" & Join(parv), ":" & cptr.Nick
End Function

Public Function m_memoserv(cptr As clsClient, sptr As clsClient, parv$()) As Long
Set sptr = GlobUsers("memoserv")
If sptr Is Nothing Then
    SendWsock cptr.index, ERR_SERVICESDOWN & " " & cptr.Nick & " MS", ":Services are currently down. Please try again later."
    Exit Function
End If
SendWsock sptr.FromLink.index, "PRIVMSG MemoServ", ":" & Join(parv), ":" & cptr.Nick
End Function

Public Function m_operserv(cptr As clsClient, sptr As clsClient, parv$()) As Long
Set sptr = GlobUsers("operserv")
If sptr Is Nothing Then
    SendWsock cptr.index, ERR_SERVICESDOWN & " " & cptr.Nick & " OS", ":Services are currently down. Please try again later."
    Exit Function
End If
SendWsock sptr.FromLink.index, "PRIVMSG OperServ", ":" & Join(parv), ":" & cptr.Nick
End Function

Public Function m_vhost(cptr As clsClient, sptr As clsClient, parv$()) As Long
If Len(parv(0)) = 0 Then
    SendWsock cptr.index, ERR_NEEDMOREPARAMS & " " & cptr.Nick, TranslateCode(ERR_NEEDMOREPARAMS, , , "VHOST")
    Exit Function
End If
If UBound(parv) < 1 Then
    SendWsock cptr.index, ERR_NEEDMOREPARAMS & " " & cptr.Nick, TranslateCode(ERR_NEEDMOREPARAMS, , , "VHOST")
    Exit Function
End If
Call DoVLine(cptr, parv(0), parv(1))
End Function

Public Function m_ircx_data(cptr As clsClient, sptr As clsClient, parv$(), DataRequestReply As Long) As Long
#If Debugging = 1 Then
    SendSvrMsg "DATA/REQUEST/REPLY called! (" & cptr.Nick & ")"
#End If
Dim cmd$, RecList$(), i, x&, Chan As clsChannel, Recp As clsClient, RecvServer() As clsClient, ChM As clsChanMember
'Command: DATA/REQUEST/REPLY <target> <tag> :<message>
'Reply:   :<sender> :DATA/REQUEST/REPLY <target> <tag> :<message>
'(there should be a flag to include or exclude the colon?)

If cptr.AccessLevel = 4 Then
    If DataRequestReply = 0 Then
        cmd = "DATA"
    ElseIf DataRequestReply = 1 Then
        cmd = "REQUEST"
    Else
        cmd = "REPLY"
    End If
    
    RecList = Split(parv(0), ",")
    For Each i In RecList
        If AscW(CStr(i)) = 35 Then
            Set Chan = Channels(CStr(i))
            If Chan Is Nothing Then GoTo NextCmd
            'If SendIRCXDataToChan(Chan, sptr, cmd, parv(1), parv(2), cptr.Nick) Then
            If SendToChan(Chan, sptr.Prefix & " " & cmd & " " & Chan.Name & " " & parv(1) & " :" & parv(2), cptr.Nick) Then
                SendToServer_ButOne cmd & " " & Chan.Name & " " & parv(1) & " :" & parv(2), cptr.ServerName, sptr.Nick
            End If
        Else
            Set Recp = GlobUsers(CStr(i))
            If Recp Is Nothing Then
                'SendWsock cptr.Index, "KILL " & CStr(i), ":" & i & " <-- Unknown client"
                GoTo NextCmd
            End If
            If Recp.Hops > 0 Then
                'The user is a remote user
                SendWsock Recp.FromLink.index, cmd & " " & Recp.Nick & " " & parv(1), ":" & parv(2), ":" & sptr.Nick
            Else
                'the user is an local user
                SendWsock Recp.index, cmd & " " & Recp.Nick & " " & parv(1), ":" & parv(2), sptr.Prefix
            End If
        End If
NextCmd:
    Next
Else
    'the IRCX draft says that only IRCX users can use data
    If Not cptr.IsIRCX Then
      SendWsock cptr.index, ERR_UNKNOWNCOMMAND & " " & cptr.Nick, TranslateCode(ERR_UNKNOWNCOMMAND, , , cmd)
      Exit Function
    End If
    If Len(parv(0)) = 0 Then 'if no recipient is given, return an error -Dill
      SendWsock cptr.index, ERR_NORECIPIENT & " " & cptr.Nick, TranslateCode(ERR_NORECIPIENT, cmd)
      Exit Function
    End If
    If UBound(parv) = 1 Then 'if cptr didnt tell us what to send, complain -Dill
      SendWsock cptr.index, ERR_NOTEXTTOSEND & " " & cptr.Nick, TranslateCode(ERR_NOTEXTTOSEND)
      Exit Function
    End If
    If cptr.IsGagged Then 'if they're gagged, they can't speak (or send data)
      If BounceGagMsg Then SendWsock cptr.index, IRCERR_SECURITY & " " & cptr.Nick, TranslateCode(IRCERR_SECURITY)
      Exit Function
    End If
    
    If DataRequestReply = 0 Then
        cmd = "DATA"
    ElseIf DataRequestReply = 1 Then
        cmd = "REQUEST"
    Else
        cmd = "REPLY"
    End If
    
    RecList = Split(parv(0), ",")
    For Each i In RecList
      If Len(i) = 0 Then GoTo nextmsg
      If AscW(CStr(i)) = 35 Then
        'Channel message -Dill
        Set Chan = Channels(CStr(i))
        If Chan Is Nothing Then 'In case Channel does not exist -Dill
          SendWsock cptr.index, ERR_NOSUCHNICK, cptr.Nick & " " & TranslateCode(ERR_NOSUCHNICK, CStr(i))
          GoTo nextmsg
        End If
        With Chan
            'I know NOEXTERN should apply to DATA/REQUEST/REPLY (it's only logical)
            'but what about the moderated thing?
            If .IsNoExternalMsgs Then
                If .GetUser(cptr.Nick) Is Nothing Then
                  SendWsock cptr.index, ERR_CANNOTSENDTOCHAN, cptr.Nick & " " & TranslateCode(ERR_CANNOTSENDTOCHAN, .Name)
                  GoTo nextmsg
                End If
            End If
            If .IsModerated Then
              Set ChM = .Member.Item(cptr.Nick)
              If Not (ChM.IsVoice Or ChM.IsOp Or ChM.IsOwner) Then
                  SendWsock cptr.index, ERR_CANNOTSENDTOCHAN, cptr.Nick & " " & TranslateCode(ERR_CANNOTSENDTOCHAN, , .Name)
                  Set ChM = Nothing
                  GoTo nextmsg
              End If
              Set ChM = Nothing
            End If
            If IsBanned(Chan, cptr) Then
                SendWsock cptr.index, ERR_CANNOTSENDTOCHAN, cptr.Nick & " " & TranslateCode(ERR_CANNOTSENDTOCHAN, , .Name)
                GoTo nextmsg
            End If
            'check tags
            If Left$(UCase$(parv(1)), 3) = "ADM" Then
              If Not cptr.IsNetAdmin Then
                SendWsock cptr.index, IRCERR_BADTAG, cptr.Nick & " " & TranslateCode(IRCERR_BADTAG, , , cmd)
                Exit Function
              End If
            ElseIf Left$(UCase$(parv(1)), 3) = "SYS" Then
              If Not (cptr.IsLocOperator Or cptr.IsGlobOperator) Then
                SendWsock cptr.index, IRCERR_BADTAG, cptr.Nick & " " & TranslateCode(IRCERR_BADTAG, , , cmd)
                Exit Function
              End If
            ElseIf Left$(UCase$(parv(1)), 3) = "OWN" Then
              If Not Chan.Member.Item(cptr.Nick).IsOwner Then
                SendWsock cptr.index, IRCERR_BADTAG, cptr.Nick & " " & TranslateCode(IRCERR_BADTAG, , , cmd)
                Exit Function
              End If
            ElseIf Left$(UCase$(parv(1)), 3) = "HST" Then
              If Not (Chan.Member.Item(cptr.Nick).IsOp Or Chan.Member.Item(cptr.Nick).IsOwner) Then
                SendWsock cptr.index, IRCERR_BADTAG, cptr.Nick & " " & TranslateCode(IRCERR_BADTAG, , , cmd)
                Exit Function
              End If
            End If
            'tags are OK! send along now :)
            If SendToChan(Chan, cptr.Prefix & " " & cmd & " " & .Name & " " & parv(1) & " :" & parv(2), cptr.Nick) Then
                SendToServer cmd & " " & .Name & " " & parv(1) & " :" & parv(2), cptr.Nick
            End If
        End With
        'reset idle time
        cptr.Idle = UnixTime
      Else
        'user message -Dill
        If InStr(1, i, "*") <> 0 Then
          If Not (cptr.IsLocOperator Or cptr.IsGlobOperator) Then 'Can't send to wildcarded recipient list if not an oper -Dill
            SendWsock cptr.index, ERR_NOPRIVILEGES & " " & cptr.Nick, TranslateCode(ERR_NOPRIVILEGES)
            Exit Function
          Else
            'WILDCARD recievelist -Dill
            Dim Umask$, Target() As clsClient
            Umask = ":" & CreateMask(CStr(i))
            Target = GlobUsers.Values
            
            'check tags
            If Left$(UCase$(parv(1)), 3) = "ADM" Then
              If Not cptr.IsNetAdmin Then
                SendWsock cptr.index, IRCERR_BADTAG, cptr.Nick & " " & TranslateCode(IRCERR_BADTAG, , , cmd)
                Exit Function
              End If
            ElseIf Left$(UCase$(parv(1)), 3) = "SYS" Then
              If Not (cptr.IsLocOperator Or cptr.IsGlobOperator) Then
                SendWsock cptr.index, IRCERR_BADTAG, cptr.Nick & " " & TranslateCode(IRCERR_BADTAG, , , cmd)
                Exit Function
              End If
            'we're allowing OWN and HST tags because this part can only be executed by opers
            'and obviously we don't care about owners or hosts :)
            End If
            'tags are OK! send along now :)
            
            For x = LBound(Target) To UBound(Target)
                If Target(x).Prefix Like Umask Then
                    If Target(x).Hops = 0 Then
                        SendWsock Target(x).index, cmd & " " & Target(x).Nick & " " & parv(1), ":" & parv(2), cptr.Prefix
                    Else
                        SendWsock Target(x).FromLink.index, cmd & " " & Target(x).Nick & " " & parv(1), ":" & parv(2), ":" & cptr.Nick
                    End If
                End If
            Next x
            GoTo nextmsg
          End If
        End If
        On Local Error Resume Next
        
        'yes, we ARE reusing sptr because we're lazy bums
        'TODO: stop being lazy
        Set sptr = GlobUsers(CStr(i))
        If sptr Is Nothing Then
          SendWsock cptr.index, ERR_NOSUCHNICK, cptr.Nick & " " & TranslateCode(ERR_NOSUCHNICK, CStr(i))
          GoTo nextmsg
        End If
        
        'check tags
        If Left$(UCase$(parv(1)), 3) = "ADM" Then
          If Not cptr.IsNetAdmin Then
            SendWsock cptr.index, IRCERR_BADTAG, cptr.Nick & " " & TranslateCode(IRCERR_BADTAG, , , cmd)
            Exit Function
          End If
        ElseIf Left$(UCase$(parv(1)), 3) = "SYS" Then
          If Not (cptr.IsLocOperator Or cptr.IsGlobOperator) Then
            SendWsock cptr.index, IRCERR_BADTAG, cptr.Nick & " " & TranslateCode(IRCERR_BADTAG, , , cmd)
            Exit Function
          End If
        'for the record, you can NOT be an owner or a host when sending directly!
        'if you can, please someone tell me, because as far as I know it's physically impossible
        'since there is no context of a channel
        ElseIf Left$(UCase$(parv(1)), 3) = "OWN" Then
          SendWsock cptr.index, IRCERR_BADTAG, cptr.Nick & " " & TranslateCode(IRCERR_BADTAG, , , cmd)
          Exit Function
        ElseIf Left$(UCase$(parv(1)), 3) = "HST" Then
          SendWsock cptr.index, IRCERR_BADTAG, cptr.Nick & " " & TranslateCode(IRCERR_BADTAG, , , cmd)
          Exit Function
        End If
        'tags are OK! send along now :)
        
        'deliver the message -Dill
        If sptr.Hops = 0 Then
            SendWsock sptr.index, cmd & " " & sptr.Nick & " " & parv(1), ":" & parv(2), cptr.Prefix
        Else
            SendWsock sptr.FromLink.index, cmd & " " & sptr.Nick & " " & parv(1), ":" & parv(2), ":" & cptr.Nick
        End If
        
        'should we really send the away msg if they're away?
        If Len(sptr.AwayMsg) > 0 Then
            SendWsock cptr.index, RPL_AWAY & " " & cptr.Nick & " " & sptr.Nick, ":" & sptr.AwayMsg
        End If
        'reset idle time
        cptr.Idle = UnixTime
      End If
nextmsg:
    Next
End If
End Function
