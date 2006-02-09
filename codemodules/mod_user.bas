Attribute VB_Name = "mod_user"
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
' $Id: mod_user.bas,v 1.3 2004/05/28 20:20:54 ziggythehamster Exp $
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
#Const SendMessageOnInvalidLogin = 0
#Const Debugging = 0

Public Function do_nick_name(Nick$) As Long
#If Debugging = 1 Then
    SendSvrMsg "DoNickName called! (" & Nick & ")"
#End If
Dim I&
'A'..'}', '_', '-', '0'..'9'
If IsNumeric(Left$(Nick, 1)) Then Exit Function
If Left$(Nick, 1) = "-" Then Exit Function
If StrComp(Nick, "anonymous", vbTextCompare) = 0 Then Exit Function
For I = 1 To Len(Nick)
    If Not IsValidString(Mid$(Nick, I, 1)) Then Exit Function
Next I
do_nick_name = 1
End Function
Public Function do_user_name(User$) As Long
#If Debugging = 1 Then
    SendSvrMsg "DoUserName called! (" & User & ")"
#End If
Dim I&
'A'..'}', '_', '-', '0'..'9'
If IsNumeric(Left$(User, 1)) Then Exit Function
If Left$(User, 1) = "-" Then Exit Function
If StrComp(User, "anonymous", vbTextCompare) = 0 Then Exit Function
For I = 1 To Len(User)
    If Not IsValidUserString(Mid$(User, I, 1)) Then Exit Function
Next I
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
        ElseIf (strAsc > 122 And strString <> "_") Then
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
Dim pdat$, I&, tempVar$
If cptr.AccessLevel = 4 Then
    WhereAmI = "server nick"
    If UBound(parv) > 0 Then
        #If Debugging = 1 Then
          SendSvrMsg "server nick - ubound(parv) > 0"
        #End If
        Dim NewCptr As clsClient, MSwitch As Boolean
        MSwitch = True
        WhereAmI = "getting global user..."
        Set NewCptr = GlobUsers(parv(1))
        If Not NewCptr Is Nothing Then
            WhereAmI = "nick collision"
            m_error NewCptr, "Nick Collision"
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
                    .Host = UCase(modMD5.oMD5.MD5(parv(4)))
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
            If IrcStat.MaxGlobUsers < IrcStat.GlobUsers Then IrcStat.MaxGlobUsers = IrcStat.MaxGlobUsers + 1
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
          SendSvrMsg "server nick - ubound(parv) else [<=0]"
        #End If
        SendToServer_ButOne "NICK " & parv(0), cptr.ServerName, sptr.Nick
        Dim ByteArr() As Byte, Members() As clsChanMember
        ByteArr = StrConv(sptr.Prefix & " NICK " & parv(0) & vbCrLf, vbFromUnicode)
        Dim RecvArr() As Long: ReDim RecvArr(0)
        For m_nick = 1 To cptr.OnChannels.Count
          Members = sptr.OnChannels.Item(m_nick).Member.Values
          For I = LBound(Members) To UBound(Members)
            If Members(I).Member.Hops = 0 Then
              If Not Members(I).Member Is sptr Then
                ReDim Preserve RecvArr(UBound(RecvArr) + 1)
                RecvArr(UBound(RecvArr)) = Members(I).Member.index
              End If
            End If
          Next I
        Next m_nick
        KillDupes RecvArr
        ServerTraffic = ServerTraffic + (UBound(RecvArr) * UBound(ByteArr))
        For I = 1 To UBound(RecvArr)
            Call Send(Sockets.SocketHandle(CLng(RecvArr(I))), ByteArr(0), UBound(ByteArr) + 1, 0&)
        Next I
        GlobUsers.Remove sptr.Nick
        sptr.Nick = parv(0)
        GlobUsers.Add parv(0), sptr
        sptr.Prefix = ":" & sptr.Nick & "!" & sptr.User & "@" & sptr.Host
    End If
Else
  WhereAmI = "use nick"
  Dim Temp$
  If Len(parv(0)) = 0 Then  'In case client didn't send a nick along -Dill
    WhereAmI = "no nickname given"
    SendWsock cptr.index, ERR_NONICKNAMEGIVEN & " " & cptr.Nick, TranslateCode(ERR_NONICKNAMEGIVEN)
    Exit Function
  End If
  If AscW(parv(0)) = 58 Then parv(0) = Mid$(parv(0), 2)
  If NickLen > 0 Then
    parv(0) = Mid$(parv(0), 1, NickLen)
  End If
  If StrComp(cptr.Nick, parv(0)) = 0 Then Exit Function
  WhereAmI = "check nick for illegal characters"
  If do_nick_name(parv(0)) = 0 Then 'in case client send a nick with illegal char's along -Dill
    SendWsock cptr.index, ERR_ERRONEUSNICKNAME & " " & cptr.Nick, TranslateCode(ERR_ERRONEUSNICKNAME, parv(0))
    Exit Function
  End If
  I = GetQLine(parv(0), cptr.AccessLevel)
  WhereAmI = "normal nick crap"
  If I > 0 Then
    'the original people added another parameter that didn't need to be there
    SendWsock cptr.index, ERR_ERRONEUSNICKNAME & " " & parv(0), QLine(I).Reason & " [" & QLine(I).Nick & "]"
    Exit Function
  End If
  If Not GlobUsers(parv(0)) Is Nothing Then  'in case the nickname specified is already in use -Dill
    SendWsock cptr.index, ERR_NICKNAMEINUSE & " " & cptr.Nick, TranslateCode(ERR_NICKNAMEINUSE, parv(0))
    Exit Function
  End If
  If cptr.OnChannels.Count > 0 Then
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
    
    Dim AllVisible As New Collection
    ReDim RecvArr(1)
    For m_nick = 1 To cptr.OnChannels.Count
      Members = cptr.OnChannels.Item(m_nick).Member.Values
      For I = LBound(Members) To UBound(Members)
        If Members(I).Member.Hops = 0 Then
          If Not Members(I).Member Is cptr Then
            On Local Error Resume Next
            AllVisible.Add Members(I).Member.index, CStr(Members(I).Member.index)
          End If
        End If
      Next I
    Next m_nick
    For I = 1 To AllVisible.Count
      Call SendWsock(AllVisible(I), "NICK", parv(0), ":" & cptr.Nick)
    Next I
    SendToServer "NICK " & parv(0), ":" & cptr.Nick
  End If
  'if the user is not currently registering, tell it the new nickname -Dill
  If Len(cptr.Nick) = 0 Then
    If cptr.PassOK = False Then
        m_error cptr, "Closing Link: (Bad Password)"
        Exit Function
    End If
    SendWsock cptr.index, "NOTICE AUTH", ":*** If you experience problems while connecting please email the admin (" & mod_list.AdminEmail & ") about it and include the server you tried to connect to (" & ServerName & ")."
    If Len(cptr.User) > 0 Then
      pdat = GetRand
      SendWsock cptr.index, "NOTICE AUTH", ":*** If you experience problems due to PING timeouts, type '/raw PONG :" & pdat & "' now."
      SendWsock cptr.index, "PING " & pdat, vbNullString, , True
      IrcStat.UnknownConnections = IrcStat.UnknownConnections - 1
    End If
  Else
    pdat = parv(0)
    SendWsock cptr.index, "NICK", pdat, ":" & cptr.Nick
  End If
  'assign the new nick to the database -Dill
  If Len(cptr.Nick) > 0 Then GlobUsers.Remove cptr.Nick
  GlobUsers.Add parv(0), cptr
  tempVar = cptr.Nick
  cptr.Nick = parv(0)
  GenerateEvent "USER", "NICKCHANGE", Replace(cptr.Prefix, ":", ""), Replace(cptr.Prefix, ":", "") & " " & cptr.Nick
  cptr.Prefix = ":" & cptr.Nick & "!" & cptr.User & "@" & cptr.Host
  Dim WasOwner As Boolean, WasOp As Boolean, WasHOp As Boolean, WasVoice As Boolean
  Dim tmpData As Integer
  For m_nick = 1 To cptr.OnChannels.Count
       With cptr.OnChannels.Item(m_nick).Member
         WasOwner = .Item(tempVar).IsOwner
         WasOp = .Item(tempVar).IsOp
         WasHOp = .Item(tempVar).IsHOp
         WasVoice = .Item(tempVar).IsVoice
         tmpData = 0
         If WasOwner Then tmpData = 6
         If WasOp Then tmpData = 4 'WTF is this bit for? Any Ideas Ziggy? - DG
                                'looks like a temp variable for the user level - Ziggy
         If WasVoice Then tmpData = tmpData + 1
         .Remove tempVar
         .Add CLng(tmpData), cptr
       End With
  Next m_nick
End If
Exit Function

NickError:
SendSvrMsg "Error in NICK processing code at " & WhereAmI & ". Error: " & err.Number & " - " & err.Description
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
Dim cmd$, RecList$(), I, x&, Chan As clsChannel, Recp As clsClient, RecvServer() As clsClient, ChM As clsChanMember
If cptr.AccessLevel = 4 Then
    If Notice Then
        cmd = "NOTICE"
    Else
        cmd = "PRIVMSG"
    End If
    RecList = Split(parv(0), ",")
    For Each I In RecList
        If AscW(CStr(I)) = 35 Then
            Set Chan = Channels(CStr(I))
            If Chan Is Nothing Then GoTo NextCmd
            If SendToChan(Chan, sptr.Prefix & " " & cmd & " " & Chan.Name & " :" & parv(1), cptr.Nick) Then
                SendToServer_ButOne cmd & " " & Chan.Name & " :" & parv(1), cptr.ServerName, sptr.Nick
            End If
        Else
            Set Recp = GlobUsers(CStr(I))
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
    If Notice Then
        cmd = " NOTICE "
    Else
        cmd = " PRIVMSG "
    End If
    RecList = Split(parv(0), ",")
    For Each I In RecList
      If Len(I) = 0 Then GoTo nextmsg
      If AscW(CStr(I)) = 35 Then
        'Channel message -Dill
        Set Chan = Channels(CStr(I))
        If Chan Is Nothing Then 'In case Channel does not exist -Dill
          SendWsock cptr.index, ERR_NOSUCHNICK, cptr.Nick & " " & TranslateCode(ERR_NOSUCHNICK, CStr(I))
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
              If Not (ChM.IsVoice Or ChM.IsHOp Or ChM.IsOp Or ChM.IsOwner) Then
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
            If SendToChan(Chan, cptr.Prefix & cmd & .Name & " :" & parv(1), cptr.Nick) Then
                SendToServer Trim$(cmd) & " " & .Name & " :" & parv(1), cptr.Nick
            End If
        End With
        'reset idle time
        cptr.Idle = UnixTime
      Else
        'user message -Dill
        If InStr(1, I, "*") <> 0 Then
          If Not (cptr.IsLocOperator Or cptr.IsGlobOperator) Then 'Can't send to wildcarded recipient list if not an oper -Dill
            SendWsock cptr.index, ERR_NOPRIVILEGES & " " & cptr.Nick, TranslateCode(ERR_NOPRIVILEGES)
            Exit Function
          Else
            'WILDCARD recievelist -Dill
            Dim Umask$, Target() As clsClient
            Umask = ":" & CreateMask(CStr(I))
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
        Set sptr = GlobUsers(CStr(I))
        If sptr Is Nothing Then 'in case user does not exist -Dill
          SendWsock cptr.index, ERR_NOSUCHNICK, cptr.Nick & " " & TranslateCode(ERR_NOSUCHNICK, CStr(I))
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
      End If
nextmsg:
    Next
End If
End Function

'/*
'** m_who
'**  parv[0] = sender prefix
'**  parv[1] = nickname mask list
'**  parv[2] = additional selection flag, only 'o' for now. - WTF?!?!?! THERE IS NO /WHO o OPTION (DG)
'*/

Public Function m_who(cptr As clsClient, sptr As clsClient, parv$()) As Long
#If Debugging = 1 Then
    SendSvrMsg "WHO called! (" & cptr.Nick & ")"
#End If
On Error Resume Next
Dim I&, x&, lastchan$, Chan As clsChannel, ChanMember As clsClient, ret As Long, Clients() As clsClient, ChM() As clsChanMember, ExtraInfo$
If cptr.AccessLevel = 4 Then
Else
    If Len(parv(0)) = 0 Then  'if no mask is given, complain -Dill
        SendWsock cptr.index, ERR_NEEDMOREPARAMS & " " & cptr.Nick, TranslateCode(ERR_NEEDMOREPARAMS, , , "WHO")
        Exit Function
    End If
    If AscW(parv(0)) = 35 Then
        Set Chan = Channels(parv(0))
        If Chan Is Nothing Then
            SendWsock cptr.index, SPrefix & " " & 315 & " " & cptr.Nick & " " & parv(0) & " :End of /WHO list.", vbNullString, , True
            Exit Function
        End If
        ChM = Chan.Member.Values
        For I = LBound(ChM) To UBound(ChM)
            If MaxWhoLen > 0 Then
                If ret = MaxWhoLen Then
                    SendWsock cptr.index, 315 & " " & cptr.Nick & " " & parv(0), ":Too many matches"
                    Exit Function
                End If
            End If
            With ChM(I).Member
                If Len(.AwayMsg) > 0 Then
                    ExtraInfo = "G"
                Else
                    ExtraInfo = "H"
                End If
                If ChM(I).IsOwner Then
                    ExtraInfo = ExtraInfo & "."
                ElseIf ChM(I).IsOp Then
                    ExtraInfo = ExtraInfo & "@"
                ElseIf ChM(I).IsHOp Then
                    ExtraInfo = ExtraInfo & "%"
                ElseIf ChM(I).IsVoice Then
                    ExtraInfo = ExtraInfo & "+"
                End If
                If .IsGlobOperator Or .IsLocOperator Then ExtraInfo = ExtraInfo & "*"
                SendWsock cptr.index, 352 & " * " & Chan.Name & " " & .User & " " & .Host & " " & ServerName & " " & .Nick & " " & ExtraInfo, ":" & .Hops & " " & .Name
                ExtraInfo = vbNullString
            End With
            ret = ret + 1
        Next I
    Else
        Clients = GlobUsers.Values
        If Not Clients(0) Is Nothing Then
            For I = 0 To UBound(Clients)
                If MaxWhoLen > 0 Then
                    If ret = MaxWhoLen Then
                        SendWsock cptr.index, 315 & " " & cptr.Nick & " " & parv(0), ":Too many matches"
                        Exit Function
                    End If
                End If
                If Clients(I).Prefix Like parv(0) Then
                    If Clients(I).OnChannels.Count > 0 Then
                        lastchan = Clients(I).OnChannels.Item(Clients(I).OnChannels.Count).Name & " "
                    Else
                        lastchan = "* "
                    End If
                    If Len(Clients(I).AwayMsg) > 0 Then
                      ExtraInfo = "G"
                    Else
                      ExtraInfo = "H"
                    End If
                    If Clients(I).IsGlobOperator Or Clients(I).IsLocOperator Then ExtraInfo = ExtraInfo & "*"
                    SendWsock cptr.index, 352 & " * " & lastchan & Clients(I).User & " " & Clients(I).Host & " " & ServerName & " " & Clients(I).Nick & " " & ExtraInfo, ":" & Clients(I).Hops & " " & Clients(I).Name
                    ret = ret + 1
                End If
            Next I
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
Dim A$(), I&, c As clsClient
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
    SendWsock cptr.index, ERR_NEEDMOREPARAMS & " " & cptr.Nick, TranslateCode(ERR_NEEDMOREPARAMS, , , "WHOIS")
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
            SendWsock cptr.index, Target(x).GetWhois(cptr.Nick), vbNullString, , True
          End If
        Next x
        SendWsock cptr.index, RPL_ENDOFWHOIS & " " & cptr.Nick & " " & parv(0), ":End of WHOIS list"
      End If
    Else
      A = Split(parv(0), ",") 'in case we have multiple queries -Dill
      'return results for all queries -Dill
      For I = LBound(A) To UBound(A)
        If Not Len(A(I)) = 0 Then
          Set c = GlobUsers(A(I))
          If c Is Nothing Then
            SendWsock cptr.index, ERR_NOSUCHNICK, cptr.Nick & " " & TranslateCode(ERR_NOSUCHNICK, A(I))
          Else
            c.WhoisAccessLevel = cptr.AccessLevel
            #If Debugging = 1 Then
              SendSvrMsg "getting whois for " & c.Nick & "; host: " & c.RealHost
            #End If
            SendWsock cptr.index, c.GetWhois(cptr.Nick), vbNullString, , True
          End If
        End If
      Next I
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
            SendWsock cptr.index, c.GetWhois(cptr.Nick), vbNullString, , True
        End If
    End If
  End If
End If
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
  If Len(parv(0)) = 0 Then
    SendWsock cptr.index, ERR_NEEDMOREPARAMS & " " & cptr.Nick, TranslateCode(ERR_NEEDMOREPARAMS, , , "USER")
    Exit Function
  End If
  If UBound(parv) = 0 Then
    SendWsock cptr.index, ERR_NEEDMOREPARAMS & " " & cptr.Nick, TranslateCode(ERR_NEEDMOREPARAMS, , , "USER")
    Exit Function
  End If
  If Len(cptr.User) <> 0 Then
    SendWsock cptr.index, ERR_ALREADYREGISTRED & " " & cptr.Nick, TranslateCode(ERR_ALREADYREGISTRED)
    Exit Function
  End If
  Dim Ident$, pdat$, I&, x&, z&, allusers() As clsClient
  If IsValidUserString(parv(0)) = True Then
  With cptr
    .User = parv(0)
    .Name = parv(3)
    If DoKLine(cptr) Then
        cptr.IsKilled = True
        cptr.SendQ = vbNullString
        KillStruct cptr.Nick
        IrcStat.UnknownConnections = IrcStat.UnknownConnections - 1
        Exit Function
    End If
    If .PassOK = False Then
        m_error cptr, "Closing Link: (Bad Password)"
        Exit Function
    End If
    If Die = True Then
        For x = 1 To .OnChannels.Count
            SendToChan .OnChannels.Item(x), .Prefix & " AutoKilled: Server Misconfigured", vbNullString
        Next x
        SendToServer "QUIT :AutoKilled: Server Misconfigured", .Nick
        SendWsock .index, "KILL " & .Nick, ":AutoKilled: Server Misconfigured", .Prefix
        m_error cptr, "Closing Link: (AutoKilled: Server Misconfigured)"
        .IsKilled = True
        KillStruct .Nick
        Exit Function
    End If
    If OfflineMode = True Then
        If OfflineMessage = "" Then
            For x = 1 To .OnChannels.Count
                SendToChan .OnChannels.Item(x), .Prefix & " AutoKilled: Server In Offline Mode", vbNullString
            Next x
            SendToServer "QUIT :AutoKilled: Server In Offline Mode", .Nick
            SendWsock .index, "KILL " & .Nick, ":AutoKilled: Server In Offline Mode", .Prefix
            m_error cptr, "Closing Link: (AutoKilled: Server In Offline Mode)"
            .IsKilled = True
            KillStruct .Nick
            Exit Function
        Else
            For x = 1 To .OnChannels.Count
                SendToChan .OnChannels.Item(x), .Prefix & " AutoKilled: " & OfflineMessage, vbNullString
            Next x
            SendToServer "QUIT :AutoKilled: " & OfflineMessage, .Nick
            SendWsock .index, "KILL " & .Nick, ":AutoKilled: " & OfflineMessage, .Prefix
            m_error cptr, "Closing Link: (AutoKilled: " & OfflineMessage & ")"
            .IsKilled = True
            KillStruct .Nick
            Exit Function
        End If
    End If
    
    If Len(.Nick) = 0 Then Exit Function
    pdat = GetRand
    SendWsock cptr.index, "NOTICE AUTH", ":*** If you experience problems due to PING timeouts, type '/raw PONG :" & pdat & "' now"
    If Not CustomNotice = "" Then
        SendWsock cptr.index, "NOTICE AUTH", ":*** " & CustomNotice
    End If
    SendWsock cptr.index, "PING " & pdat, vbNullString, , True
    IrcStat.UnknownConnections = IrcStat.UnknownConnections - 1
  End With
  Else
  With cptr
  For x = 1 To .OnChannels.Count
    SendToChan .OnChannels.Item(x), .Prefix & " AutoKilled: Improper Ident - Please Change to a Alphanumeric Combination.", vbNullString
    Next x
    SendToServer "QUIT :AutoKilled: Improper Ident - Please Change to a Alphanumeric Combination.", .Nick
    SendWsock .index, "KILL " & .Nick, ":AutoKilled: Improper Ident - Please Change to a Alphanumeric Combination.", .Prefix
    m_error cptr, "Closing Link: (AutoKilled: Improper Ident - Please Change to a Alphanumeric Combination.)"
    .IsKilled = True
    KillStruct .Nick
    Exit Function
  End With
  End If
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
    Dim I As Long
    For I = 1 To sptr.OnChannels.Count
        SendToChan sptr.OnChannels.Item(I), sptr.Prefix & " QUIT :" & parv(0), vbNullString
    Next I
    KillStruct sptr.Nick
    SendToServer_ButOne "QUIT " & sptr.Nick & " :" & parv(0), cptr.ServerName, sptr.Nick
    Set sptr = Nothing
Else
    On Error Resume Next
    Dim x() As clsChanMember, Chan As clsChannel, Msg As String, y&
    If Len(parv(0)) = 0 Then parv(0) = "Exit: (" & cptr.Nick & ")"
    If QuitLen > 0 Then
        parv(0) = Mid$(parv(0), 1, QuitLen)
    End If
    Msg = cptr.Prefix & " QUIT :Exit: " & parv(0) & vbCrLf
    For y = 1 To cptr.OnChannels.Count
        x = cptr.OnChannels.Item(y).Member.Values
        For I = LBound(x) To UBound(x)
            If x(I).Member.Hops = 0 Then
                With x(I).Member
                    .SendQ = .SendQ & Msg
                    ColOutClientMsg.Add .index
                End With
            End If
        Next I
        cptr.OnChannels.Item(y).Member.Remove cptr.Nick
    Next
    m_error cptr, "Closing Link: (Exit: " & parv(0) & ")" 'confirm the quit and disconnect the client -Dill
    SendToServer "QUIT " & cptr.Nick & " :" & parv(0), cptr.Nick
    KillStruct cptr.Nick
    Set cptr = Nothing
End If
End Function
'/*
'** m_kill
'**  parv[0] = sender prefix
'**  parv[1] = kill victim
'**  parv[2] = kill path
'*/
Public Function m_kill(cptr As clsClient, sptr As clsClient, parv$()) As Long
#If Debugging = 1 Then
   SendSvrMsg "KILL called! (" & cptr.Nick & ")"
#End If
Dim y&, User As clsClient, I&, x&, allusers() As clsClient, sender$, QMsg$, Killed() As clsClient
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
   If InStr(1, parv(0), "*") > 0 Then
       If Not cptr.CanGlobKill Then
           SendWsock cptr.index, ERR_NOPRIVILEGES & " " & cptr.Nick, TranslateCode(ERR_NOPRIVILEGES)
           Exit Function
       End If
       QMsg = " QUIT :Killed by " & cptr.Nick & " (" & parv(1) & ")"
       SendSvrMsg "Recieved KILL message for " & parv(0) & " from " & cptr.Nick & " (" & parv(1) & ")" '// include reason -ziggy
       parv(0) = CreateMask(parv(0))
       allusers = GlobUsers.Values
       For I = LBound(allusers) To UBound(allusers)
           '// now THIS could be a major problem
           '// we need to make sure that the AccessLevel is 4, and the user wanted to kill the server in the first place
           '// since this would trigger if a server was connected -ziggy
           If allusers(I).AccessLevel = 4 And UCase(allusers(I).Prefix) Like UCase(":" & parv(0)) Then '// casing does not matter -ziggy
               SendWsock cptr.index, ERR_CANTKILLSERVER & " " & cptr.Nick, TranslateCode(ERR_CANTKILLSERVER)
               Exit Function
           End If
                     If UCase(allusers(I).Prefix) Like UCase(":" & parv(0)) Then '// casing does not matter -ziggy
                             For x = 1 To allusers(I).OnChannels.Count
                   SendToChan allusers(I).OnChannels.Item(x), allusers(I).Prefix & QMsg, vbNullString
               Next x
                             If allusers(I).Hops > 0 Then
                   SendWsock allusers(I).FromLink.index, "KILL " & allusers(I).Nick, ":Killed by " & cptr.Nick & " (" & parv(1) & ")", cptr.Prefix
               Else
                   SendWsock allusers(I).index, "KILL " & allusers(I).Nick, ":Killed by " & cptr.Nick & " (" & parv(1) & ")", cptr.Prefix
                   m_error allusers(I), "Closing Link: (Killed by " & cptr.Prefix & " (" & parv(1) & "))" '// send reason -ziggy
               End If
                             KillStruct allusers(I).Nick, enmTypeClient
               allusers(I).IsKilled = True
               Set allusers(I) = Nothing
           End If
       Next I
       SendToServer "QUIT :Killed by " & cptr.Nick & " (" & parv(1) & ")", allusers(I).Nick
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
           m_error User, "Closing Link: (Killed by " & cptr.Prefix & " (" & parv(1) & "))" '// m_error disconnects the user -ziggy
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
'todo
Else
  'ignoring destination now
  If Len(parv(0)) = 0 Then
    SendWsock cptr.index, "PONG", ""
  Else
    If parv(0) = SPrefix Then
      SendWsock cptr.index, "PONG " & SPrefix, ""
    Else
      SendWsock cptr.index, "PONG " & parv(0), ""
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
    #If SendMessageOnInvalidLogin = 1 Then
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
    SendSvrMsg "PASS called! (" & cptr.Nick & ")"
#End If
If Len(parv(0)) = 0 Then
    SendWsock cptr.index, ERR_NEEDMOREPARAMS & " " & cptr.Nick, TranslateCode(ERR_NEEDMOREPARAMS, , , "PASS")
    Exit Function
End If
If cptr.PassOK = True Then m_pass = 1: Exit Function

If Not cptr.LLined Then
    If DoLLine(cptr) Then
        If StrComp(parv(0), ILine(cptr.IIndex).Pass) = 0 Then
            m_pass = 1
            cptr.PassOK = True
        Else
            m_pass = -1
            cptr.PassOK = False
        End If
    Else
        If StrComp(parv(0), LLine(cptr.IIndex).Pass) = 0 Then
            m_pass = 1
            cptr.PassOK = True
            cptr.LLined = True
        Else
            m_pass = -1
            cptr.PassOK = False
        End If
    End If
End If
If cptr.AccessLevel = 1 Then

End If
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
Dim I&, User As clsClient, ret$
If cptr.AccessLevel = 4 Then
Else
  If Len(parv(0)) = 0 Then
    SendWsock cptr.index, ERR_NEEDMOREPARAMS & " " & cptr.Nick, TranslateCode(ERR_NEEDMOREPARAMS, , , "USERHOST")
    Exit Function
  End If
  For I = 0 To UBound(parv)
    Set User = GlobUsers(parv(I))
    If Not User Is Nothing Then ret = ret & User.Nick & IIf((User.IsLocOperator Or User.IsGlobOperator), "*", vbNullString) & "=" & IIf(Len(User.AwayMsg) > 0, "-", "+") & User.User & "@" & User.Host & " "
    If I = 5 Then Exit For
  Next I
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
Dim I&, ret$, CurUser$
For I = LBound(parv) To UBound(parv)
  CurUser = parv(I)
  If Not GlobUsers(CurUser) Is Nothing Then ret = ret & CurUser & " "
Next I
SendWsock cptr.index, RPL_ISON & " " & cptr.Nick, ":" & Trim$(ret)
End Function

Public Function add_umodes(cptr As clsClient, Modes$) As String
#If Debugging = 1 Then
    SendSvrMsg "Add_umodes called! (" & cptr.Nick & ")"
#End If
Dim x&, CurMode$
For x = 1 To Len(Modes)
    CurMode = Mid$(Modes, x, 1)
    Select Case AscW(CurMode)
        Case umServerMsg
            cptr.IsServerMsg = True
            ServerMsg.Add cptr.GUID, cptr
            add_umodes = add_umodes & CurMode
        Case umLocOper
            cptr.IsLocOperator = True
            add_umodes = add_umodes & CurMode
        Case umGlobOper
            cptr.IsGlobOperator = True
            add_umodes = add_umodes & CurMode
        Case umInvisible
            cptr.IsInvisible = True
            add_umodes = add_umodes & CurMode
        Case umHostCloak
            cptr.IsCloaked = True
            add_umodes = add_umodes & CurMode
        Case umCanRehash
            cptr.CanRehash = True
            add_umodes = add_umodes & CurMode
        Case umCanRestart
            cptr.CanRestart = True
            add_umodes = add_umodes & CurMode
        Case umCanDie
            cptr.CanDie = True
            add_umodes = add_umodes & CurMode
        Case umLocRouting
            cptr.CanLocRoute = True
            add_umodes = add_umodes & CurMode
        Case umGlobRouting
            cptr.CanGlobRoute = True
            add_umodes = add_umodes & CurMode
        Case umLocKills
            cptr.CanLocKill = True
            add_umodes = add_umodes & CurMode
        Case umGlobKills
            cptr.CanGlobKill = True
            add_umodes = add_umodes & CurMode
        Case umCanKline
            cptr.CanKline = True
            add_umodes = add_umodes & CurMode
        Case umCanUnKline
            cptr.CanUnkline = True
            add_umodes = add_umodes & CurMode
        Case umRegistered
            cptr.IsRegistered = True
            add_umodes = add_umodes & CurMode
        Case umProtected
            cptr.IsProtected = True
            add_umodes = add_umodes & CurMode
        Case umNetAdmin
            cptr.IsNetAdmin = True
            cptr.IsGlobOperator = True
            add_umodes = add_umodes & CurMode
        Case umCanAdd
            cptr.CanAdd = True
            add_umodes = add_umodes & CurMode
        Case umRemoteAdmin
            cptr.IsRemoteAdmClient = True
            add_umodes = add_umodes & CurMode
    End Select
Next x
End Function

Public Function m_whowas(cptr As clsClient, sptr As clsClient, parv$()) As Long
#If Debugging = 1 Then
    SendSvrMsg "WHOWAS called! (" & cptr.Nick & ")"
#End If
If Len(parv(0)) = 0 Then
    SendWsock cptr.index, ERR_NEEDMOREPARAMS & " " & cptr.Nick, TranslateCode(ERR_NEEDMOREPARAMS, , , "WHOWAS")
    Exit Function
End If
Dim ww As typWhoWas, User$(), I&
User = Split(parv(0), ",")
For I = LBound(User) To UBound(User)
    ww = modWhoWasHashTable.Item(User(I))
    If Len(ww.Nick) > 0 Then
        SendWsock cptr.index, 314 & " " & cptr.Nick & " " & ww.Nick & " " & ww.User & " " & ww.Host & " *", ":" & ww.Name
        SendWsock cptr.index, 312 & " " & cptr.Nick & " " & ww.Nick & " " & ww.Server, ":" & ww.SignOn
    Else
        SendWsock cptr.index, 406 & " " & cptr.Nick & " " & User(I), ":There was no such nickname"
    End If
Next I
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
Public Function m_chghost(cptr As clsClient, sptr As clsClient, parv$()) As Long
'parv[0] = Nick
'parv[1] = New Host
If Not (cptr.IsLocOperator Or cptr.IsGlobOperator) Then
    SendWsock cptr.index, ERR_NOPRIVILEGES & " " & cptr.Nick, TranslateCode(ERR_NOPRIVILEGES)
    Exit Function
End If
If UBound(parv) <> 1 Then
  SendWsock cptr.index, ERR_NEEDMOREPARAMS & " " & cptr.Nick, TranslateCode(ERR_NEEDMOREPARAMS, , , "CHGHOST")
  Exit Function
End If
If Len(parv(1)) = 0 Then
  SendWsock cptr.index, ERR_NEEDMOREPARAMS & " " & cptr.Nick, TranslateCode(ERR_NEEDMOREPARAMS, , , "CHGHOST")
  Exit Function
End If
Dim User As clsClient
Set User = GlobUsers(parv(0))
If User Is Nothing Then
  SendWsock cptr.index, ERR_NOSUCHNICK, cptr.Nick & " " & TranslateCode(ERR_NOSUCHNICK, parv(0))
  Exit Function
End If
User.Host = parv(1)
SendSvrMsg "*** " & cptr.Nick & " changed the hostname of " & User.Nick & " to " & parv(1)
SendWsock User.index, "NOTICE", ":" & cptr.Nick & " changed your hostname to " & parv(1), SPrefix
End Function
Public Function m_chgnick(cptr As clsClient, sptr As clsClient, parv$()) As Long
'parv[0] = Nick
'parv[1] = New nick
If Not (cptr.IsLocOperator Or cptr.IsGlobOperator) Then
    SendWsock cptr.index, ERR_NOPRIVILEGES & " " & cptr.Nick, TranslateCode(ERR_NOPRIVILEGES)
    Exit Function
End If
If UBound(parv) <> 1 Then
  SendWsock cptr.index, ERR_NEEDMOREPARAMS & " " & cptr.Nick, TranslateCode(ERR_NEEDMOREPARAMS, , , "CHGNICK")
  Exit Function
End If
If Len(parv(1)) = 0 Then
  SendWsock cptr.index, ERR_NEEDMOREPARAMS & " " & cptr.Nick, TranslateCode(ERR_NEEDMOREPARAMS, , , "CHGNICK")
  Exit Function
End If
If Not GlobUsers(parv(1)) Is Nothing Then  'in case the nickname specified is already in use -Dill
  SendWsock cptr.index, "NOTICE", ":*** Nickname " & parv(1) & " is in use! Cannot change nickname.", SPrefix
  Exit Function
End If
Dim User As clsClient
Set User = GlobUsers(parv(0))
If User Is Nothing Then
  SendWsock cptr.index, ERR_NOSUCHNICK, cptr.Nick & " " & TranslateCode(ERR_NOSUCHNICK, parv(0))
  Exit Function
End If


Dim tmpNick As String
Dim tmpPrefix As String
Dim ByteArr() As Byte, Members() As clsChanMember
tmpNick = User.Nick
tmpPrefix = User.Prefix
User.Nick = parv(1)
SendSvrMsg "*** " & cptr.Nick & " changed the nickname of " & tmpNick & " to " & parv(1)
'now to do the standard nick change -z
Dim AllVisible As New Collection
Dim NickX As Integer
Dim I As Integer
ReDim RecvArr(1)
'notify channels -z
For NickX = 1 To User.OnChannels.Count
  Members = User.OnChannels.Item(NickX).Member.Values
  For I = LBound(Members) To UBound(Members)
    If Members(I).Member.Hops = 0 Then
      If Not Members(I).Member Is User Then
        On Local Error Resume Next
        AllVisible.Add Members(I).Member.index, CStr(Members(I).Member.index)
      End If
    End If
  Next I
Next NickX
For I = 1 To AllVisible.Count
  'send notificaiton -z
  Call SendWsock(AllVisible(I), "NICK", parv(1), tmpPrefix)
Next I
SendToServer "NICK :" & parv(1), tmpNick
SendWsock User.index, "NICK", parv(1), tmpPrefix

Dim tempVar As String
'assign the new nick to the database -Dill
If Len(User.Nick) > 0 Then GlobUsers.Remove tmpNick
GlobUsers.Add parv(1), User
tempVar = tmpNick
User.Nick = parv(1)
GenerateEvent "USER", "NICKCHANGE", Replace(tmpPrefix, ":", ""), Replace(tmpPrefix, ":", "") & " " & cptr.Nick
User.Prefix = ":" & User.Nick & "!" & User.User & "@" & User.Host
Dim WasOwner As Boolean, WasOp As Boolean, WasHOp As Boolean, WasVoice As Boolean
Dim tmpData As Integer
For NickX = 1 To User.OnChannels.Count
     With User.OnChannels.Item(NickX).Member
       WasOwner = .Item(tempVar).IsOwner
       WasOp = .Item(tempVar).IsOp
       WasHOp = .Item(tempVar).IsHOp
       WasVoice = .Item(tempVar).IsVoice
       tmpData = 0
       If WasOwner Then tmpData = 6
       If WasOp Then tmpData = 4 'WTF is this bit for? Any Ideas Ziggy? - DG
                              'looks like a temp variable for the user level - Ziggy
       If WasVoice Then tmpData = tmpData + 1
       .Remove tempVar
       .Add CLng(tmpData), User
     End With
Next NickX
End Function
Public Function m_passcrypt(cptr As clsClient, sptr As clsClient, parv$()) As Long
'parv[0] = CryptType
'parv[1] = PassToBeCrypted
Dim Pass As String
If UCase(parv(0)) = "MD5" Then
    Pass = oMD5.MD5(parv(1))
    SendWsock cptr.index, "NOTICE " & cptr.Nick, ":Encrypted " & parv(1) & " to MD5 as " & Pass, SPrefix
Else
    SendWsock cptr.index, "NOTICE " & cptr.Nick, ":Valid Options: MD5", SPrefix
End If
End Function
Public Function m_samode(cptr As clsClient, sptr As clsClient, parv$()) As Long
If Len(parv(0)) = 0 Then
    SendWsock cptr.index, ERR_NEEDMOREPARAMS & " " & cptr.Nick, TranslateCode(ERR_NEEDMOREPARAMS, , , "SAMODE")
    Exit Function
End If
If UBound(parv) < 1 Then
    SendWsock cptr.index, ERR_NEEDMOREPARAMS & " " & cptr.Nick, TranslateCode(ERR_NEEDMOREPARAMS, , , "SAMODE")
    Exit Function
End If
If Not (cptr.IsLocOperator Or cptr.IsGlobOperator) Then
    SendWsock cptr.index, ERR_NOPRIVILEGES & " " & cptr.Nick, TranslateCode(ERR_NOPRIVILEGES)
    Exit Function
End If
Dim I&, ops$, Inc&, SetMode As Boolean, Chan As clsChannel, CurMode&, ChM As clsChanMember
Dim NewModes$, Param$
Set Chan = Channels(parv(0))
If Chan Is Nothing Then
    SendWsock cptr.index, ERR_NOSUCHCHANNEL & " " & cptr.Nick, TranslateCode(ERR_NOSUCHCHANNEL, , parv(0))
    Exit Function
End If
If UBound(parv) > 1 Then Inc = 1
For I = 1 To Len(parv(1))
    CurMode = AscW(Mid$(parv(1), I, 1))
    Select Case CurMode
        Case modeAdd
            SetMode = True
            NewModes = NewModes & "+"
        Case modeRemove
            SetMode = False
            NewModes = NewModes & "-"
        Case cmOwner
            Inc = Inc + 1
            Select Case SetMode
                Case True
                    Set ChM = Chan.Member.Item(parv(Inc))
                    If Not ChM Is Nothing Then
                        If Not ChM.IsOwner Then
                            NewModes = NewModes & "q"
                            Param = Param & parv(Inc) & " "
                            ChM.IsOwner = True
                        End If
                    Else
                        SendWsock cptr.index, ERR_USERNOTINCHANNEL & " " & cptr.Nick, TranslateCode(ERR_USERNOTINCHANNEL, parv(Inc), Chan.Name)
                    End If
                Case False
                    Set ChM = Chan.Member.Item(parv(Inc))
                    If Not ChM Is Nothing Then
                        If ChM.IsOwner Then
                            NewModes = NewModes & "q"
                            Param = Param & parv(Inc) & " "
                            ChM.IsOwner = False
                        End If
                    Else
                        SendWsock cptr.index, ERR_USERNOTINCHANNEL & " " & cptr.Nick, TranslateCode(ERR_USERNOTINCHANNEL, parv(Inc), Chan.Name)
                    End If
            End Select
        Case cmOp
            Inc = Inc + 1
            Select Case SetMode
                Case True
                    Set ChM = Chan.Member.Item(parv(Inc))
                    If Not ChM Is Nothing Then
                        If Not ChM.IsOp Then
                            NewModes = NewModes & "o"
                            Param = Param & parv(Inc) & " "
                            ChM.IsOp = True
                        End If
                    Else
                        SendWsock cptr.index, ERR_USERNOTINCHANNEL & " " & cptr.Nick, TranslateCode(ERR_USERNOTINCHANNEL, parv(Inc), Chan.Name)
                    End If
                Case False
                    Set ChM = Chan.Member.Item(parv(Inc))
                    If Not ChM Is Nothing Then
                        If ChM.IsOp Then
                            NewModes = NewModes & "o"
                            Param = Param & parv(Inc) & " "
                            ChM.IsOp = False
                        End If
                    Else
                        SendWsock cptr.index, ERR_USERNOTINCHANNEL & " " & cptr.Nick, TranslateCode(ERR_USERNOTINCHANNEL, parv(Inc), Chan.Name)
                    End If
            End Select
        'Case cmHOp
        '    Inc = Inc + 1
        '    Select Case SetMode
        '        Case True
        '            Set ChM = Chan.Member.Item(parv(Inc))
        '            If Not ChM Is Nothing Then
        '                If Not ChM.IsHOp Then
        '                    NewModes = NewModes & "H"
        '                    Param = Param & parv(Inc) & " "
        '                    ChM.IsHOp = True
        '                End If
        '            Else
        '                SendWsock cptr.index, ERR_USERNOTINCHANNEL & " " & cptr.Nick, TranslateCode(ERR_USERNOTINCHANNEL, parv(Inc), Chan.Name)
        '            End If
        '        Case False
        '            Set ChM = Chan.Member.Item(parv(Inc))
        '            If Not ChM Is Nothing Then
        '                If ChM.IsHOp Then
        '                    NewModes = NewModes & "H"
        '                    Param = Param & parv(Inc) & " "
        '                    ChM.IsHOp = False
        '                End If
        '            Else
        '                SendWsock cptr.index, ERR_USERNOTINCHANNEL & " " & cptr.Nick, TranslateCode(ERR_USERNOTINCHANNEL, parv(Inc), Chan.Name)
        '            End If
        '    End Select
        Case cmVoice
            Inc = Inc + 1
            Select Case SetMode
                Case True
                    Set ChM = Chan.Member.Item(parv(Inc))
                    If Not ChM Is Nothing Then
                        If Not ChM.IsVoice Then
                            NewModes = NewModes & "v"
                            Param = Param & parv(Inc) & " "
                            ChM.IsVoice = True
                        End If
                    Else
                        SendWsock cptr.index, ERR_USERNOTINCHANNEL & " " & cptr.Nick, TranslateCode(ERR_USERNOTINCHANNEL, parv(Inc), Chan.Name)
                    End If
                Case False
                    Set ChM = Chan.Member.Item(parv(Inc))
                    If Not ChM Is Nothing Then
                        If ChM.IsVoice Then
                            NewModes = NewModes & "v"
                            Param = Param & parv(Inc) & " "
                            ChM.IsVoice = False
                        End If
                    Else
                        SendWsock cptr.index, ERR_USERNOTINCHANNEL & " " & cptr.Nick, TranslateCode(ERR_USERNOTINCHANNEL, parv(Inc), Chan.Name)
                    End If
            End Select
        Case cmBan
            Inc = Inc + 1
            Select Case SetMode
                Case True
                    NewModes = NewModes & "b"
                    Param = Param & parv(Inc) & " "
                    Chan.Bans.Add parv(Inc), cptr.Nick, UnixTime, parv(Inc)
                Case False
                    NewModes = NewModes & "b"
                    Param = Param & parv(Inc) & " "
                    Chan.Bans.Remove parv(Inc)
            End Select
        Case cmKey
            Inc = Inc + 1
            Select Case SetMode
                Case True
                    If Len(Chan.Key) = 0 Then
                        NewModes = NewModes & "k"
                        Param = Param & parv(Inc) & " "
                        Chan.Key = parv(Inc)
                    Else
                        SendWsock cptr.index, ERR_KEYSET & " " & cptr.Nick, TranslateCode(ERR_KEYSET, , , Chan.Name)
                    End If
                Case False
                    If Len(Chan.Key) > 0 Then
                        If Chan.Key = parv(Inc) Then
                            NewModes = NewModes & "k"
                            Param = Param & parv(Inc) & " "
                            Chan.Key = vbNullString
                        End If
                    End If
            End Select
        Case cmLimit
            Select Case SetMode
                Case True
                    Inc = Inc + 1
                    Chan.Limit = parv(Inc)
                    NewModes = NewModes & "l"
                    Param = Param & parv(Inc) & " "
                Case False
                    Chan.Limit = 0
                    NewModes = NewModes & "l"
            End Select
        Case cmInviteOnly
            Select Case SetMode
                Case True
                    If Not Chan.IsInviteOnly Then
                        Chan.IsInviteOnly = True
                        NewModes = NewModes & "i"
                    End If
                Case False
                    If Chan.IsInviteOnly Then
                        Chan.IsInviteOnly = False
                        NewModes = NewModes & "i"
                    End If
            End Select
        Case cmOpTopic
            Select Case SetMode
                Case True
                    If Not Chan.IsTopicOps Then
                        Chan.IsTopicOps = True
                        NewModes = NewModes & "t"
                    End If
                Case False
                    If Chan.IsTopicOps Then
                        Chan.IsTopicOps = False
                        NewModes = NewModes & "t"
                    End If
            End Select
        Case cmModerated
            Select Case SetMode
                Case True
                    If Not Chan.IsModerated Then
                        Chan.IsModerated = True
                        NewModes = NewModes & "m"
                    End If
                Case False
                    If Chan.IsModerated Then
                        Chan.IsModerated = False
                        NewModes = NewModes & "m"
                    End If
            End Select
        Case cmNoExternalMsg
            Select Case SetMode
                Case True
                    If Not Chan.IsNoExternalMsgs Then
                        Chan.IsNoExternalMsgs = True
                        NewModes = NewModes & "n"
                    End If
                Case False
                    If Chan.IsNoExternalMsgs Then
                        Chan.IsNoExternalMsgs = False
                        NewModes = NewModes & "n"
                    End If
            End Select
        Case cmSecret
            Select Case SetMode
                Case True
                    If Not Chan.IsSecret Then
                        Chan.IsSecret = True
                        NewModes = NewModes & "s"
                    End If
                Case False
                    If Chan.IsSecret Then
                        Chan.IsSecret = False
                        NewModes = NewModes & "s"
                    End If
            End Select
        Case cmPrivate
            Select Case SetMode
                Case True
                    If Not Chan.IsPrivate Then
                        Chan.IsPrivate = True
                        NewModes = NewModes & "p"
                    End If
                Case False
                    If Chan.IsPrivate Then
                        Chan.IsPrivate = False
                        NewModes = NewModes & "p"
                    End If
            End Select
    End Select
Next I
If Len(NewModes) <= 1 Then Exit Function
Param = RTrim$(Param)
SendToChan Chan, cptr.Prefix & " MODE " & Chan.Name & " " & NewModes & " " & Param, vbNullString
SendToServer "MODE " & NewModes & " " & Param, cptr.Nick
End Function

Public Function m_umode(cptr As clsClient, sptr As clsClient, parv$()) As Long
If Len(parv(0)) = 0 Then
    SendWsock cptr.index, ERR_NEEDMOREPARAMS & " " & cptr.Nick, TranslateCode(ERR_NEEDMOREPARAMS, , , "UMODE")
    Exit Function
End If
If UBound(parv) < 1 Then
    SendWsock cptr.index, ERR_NEEDMOREPARAMS & " " & cptr.Nick, TranslateCode(ERR_NEEDMOREPARAMS, , , "UMODE")
    Exit Function
End If
If Not (cptr.IsLocOperator Or cptr.IsGlobOperator) Then
    SendWsock cptr.index, ERR_NOPRIVILEGES & " " & cptr.Nick, TranslateCode(ERR_NOPRIVILEGES)
    Exit Function
End If
Dim User As clsClient, NewModes$
Set User = GlobUsers(parv(0))
If User Is Nothing Then
    SendWsock cptr.index, ERR_NOSUCHNICK & " " & cptr.Nick, TranslateCode(ERR_NOSUCHNICK, , parv(0))
    Exit Function
End If
Dim FiltModes As String
'oOsixkreRDCcKBbAEZ

FiltModes = parv(1)
FiltModes = Replace(FiltModes, "R", "")
FiltModes = Replace(FiltModes, "D", "")
FiltModes = Replace(FiltModes, "O", "")
FiltModes = Replace(FiltModes, "o", "")
FiltModes = Replace(FiltModes, "k", "")
FiltModes = Replace(FiltModes, "K", "")
FiltModes = Replace(FiltModes, "e", "")
FiltModes = Replace(FiltModes, "C", "")
FiltModes = Replace(FiltModes, "c", "")
FiltModes = Replace(FiltModes, "B", "")
FiltModes = Replace(FiltModes, "b", "")
FiltModes = Replace(FiltModes, "N", "")
FiltModes = Replace(FiltModes, "E", "")
FiltModes = Replace(FiltModes, "Z", "")


NewModes = add_umodes(User, FiltModes)
'nobody, anyone, ever should be allowed
'to give themselves or anyone else any
'oper flag

If NewModes = "" Then Exit Function
Select Case User.Hops
    Case Is > 0
        GenerateEvent "USER", "MODECHANGE", Replace(User.Prefix, ":", ""), Replace(User.Prefix, ":", "") & " +" & NewModes
        SendWsock User.FromLink.index, "MODE " & User.Nick, "+" & Replace(NewModes, "+", ""), cptr.Prefix
    Case Else
        GenerateEvent "USER", "MODECHANGE", Replace(User.Prefix, ":", ""), Replace(User.Prefix, ":", "") & " +" & NewModes
        SendWsock User.index, "MODE " & User.Nick, "+" & Replace(NewModes, "+", ""), cptr.Prefix
End Select
End Function


