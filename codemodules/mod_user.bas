Attribute VB_Name = "mod_user"
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
' $Id: mod_user.bas,v 1.17 2004/06/06 22:24:16 airwalklogik Exp $
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
If StrComp(LCase(Nick), "anonymous", vbTextCompare) = 0 Then Exit Function
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
    ':Nick NICK Nick2
    '  -2   -1   0
    'negative numbers don't count ;)
    
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
        'this is a raw send
        'perhaps we should clean this up a bit?
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
  I = GetQLine(parv(0), cptr.AccessLevel)
  WhereAmI = "normal nick crap"
  If I > 0 Then
    'the original people added another parameter that didn't need to be there
    SendWsock cptr.index, ERR_ERRONEUSNICKNAME & " " & parv(0), QLine(I).Reason & " [" & QLine(I).Nick & "]"
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
      For I = LBound(Members) To UBound(Members)
        If Members(I).Member.Hops = 0 Then
          If Not Members(I).Member Is cptr Then
            On Local Error Resume Next
            AllVisible.Add Members(I).Member.index, CStr(Members(I).Member.index)
          End If
        End If
      Next I
    Next m_nick
    
    WhereAmI = "sending nickname stuff"
    #If Debugging = 1 Then
      SendSvrMsg "NICK: main code -> sending nickname stuff"
    #End If
    
    For I = 1 To AllVisible.Count
      Call SendWsock(AllVisible(I), "NICK", parv(0), ":" & cptr.Nick)
    Next I
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
    If cptr.PassOK = False Then
        m_error cptr, "Closing Link: (Bad Password)"
        Exit Function
    End If
    WhereAmI = "if you experience problems while connecting..."
    SendWsock cptr.index, "NOTICE AUTH", ":*** If you experience problems while connecting please email the admin (" & mod_list.AdminEmail & ") about it and include the server you tried to connect to (" & ServerName & ")."
    If Len(cptr.User) > 0 Then
      pdat = GetRand
      WhereAmI = "ping timeouts"
      SendWsock cptr.index, "NOTICE AUTH", ":*** If you experience problems due to PING timeouts, type '/QUOTE PONG :" & pdat & "' or '/RAW PONG :" & pdat & "' now."
      SendWsock cptr.index, "PING " & pdat, vbNullString, , True
      IrcStat.UnknownConnections = IrcStat.UnknownConnections - 1
    End If
    WhereAmI = "custom auth notice"
    If Not Len(CustomNotice) = 0 Then 'moved so user will always see notice -AW
        SendWsock cptr.index, "NOTICE AUTH", ":*** " & CustomNotice
    End If
  Else
    WhereAmI = "set nickname"
    pdat = parv(0)
    SendWsock cptr.index, "NICK", pdat, ":" & cptr.Nick
  End If
  WhereAmI = "assign new nick to database"
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
'**  parv[2] = additional selection flag, only 'o' for now. (/who * o)
'*/

Public Function m_who(cptr As clsClient, sptr As clsClient, parv$()) As Long
#If Debugging = 1 Then
    SendSvrMsg "WHO called! (" & cptr.Nick & ")"
#End If
On Error Resume Next
Dim I&, x&, lastchan$, Chan As clsChannel, ChanMember As clsClient, ret As Long, Clients() As clsClient, ChM() As clsChanMember, ExtraInfo$
If cptr.AccessLevel = 4 Then
'todo: /who from server
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
                    If cptr.IsIRCX Or cptr.AccessLevel = 4 Then
                      ExtraInfo = ExtraInfo & "."
                    Else
                      ExtraInfo = ExtraInfo & "@"
                    End If
                ElseIf ChM(I).IsOp And Not ChM(I).IsOwner Then  '// don't send erroneous chars
                    ExtraInfo = ExtraInfo & "@"
                'ElseIf ChM(I).IsHOp Then '// kill this bugger :D
                '    ExtraInfo = ExtraInfo & "%"
                ElseIf ChM(I).IsVoice And Not ChM(I).IsOwner And Not ChM(I).IsOp Then
                    ExtraInfo = ExtraInfo & "+"
                End If
                If .IsGlobOperator Or .IsLocOperator Then ExtraInfo = ExtraInfo & "*"
                If .IsNetAdmin Then ExtraInfo = ExtraInfo & "A"
                SendWsock cptr.index, 352 & " " & cptr.Nick & " " & Chan.Name & " " & .User & " " & .Host & " " & ServerName & " " & .Nick & " " & ExtraInfo, ":" & .Hops & " " & .Name
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
                If UCase(Replace(Clients(I).Prefix, ":", "")) Like UCase(CreateMask(Replace(parv(0), ":", ""))) Then
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
                    SendWsock cptr.index, "352 " & cptr.Nick & " " & lastchan & Clients(I).User & " " & Clients(I).Host & " " & ServerName & " " & Clients(I).Nick & " " & ExtraInfo, ":" & Clients(I).Hops & " " & Clients(I).Name
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
      For I = LBound(A) To UBound(A)
        If Not Len(A(I)) = 0 Then
          Set c = GlobUsers(A(I))
          If c Is Nothing Then
            SendWsock cptr.index, ERR_NOSUCHNICK, cptr.Nick & " " & TranslateCode(ERR_NOSUCHNICK, A(I))
          Else
            c.WhoisAccessLevel = cptr.AccessLevel
            c.WhoisIRCX = cptr.IsIRCX
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
  Dim Ident$, pdat$, I&, x&, z&, allusers() As clsClient
  If IsValidUserString(parv(0)) = True Then
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
        KillStruct cptr.Nick
        IrcStat.UnknownConnections = IrcStat.UnknownConnections - 1
        Exit Function
    End If
    If .PassOK = False Then
        m_error cptr, "Closing Link: (Bad Password)"
        Exit Function
    End If
    If .IP = "127.0.0.1" And Die = True Then
        'rehash the server
        Rehash vbNullString
    End If
    If Die = True Then
        For x = 1 To .OnChannels.Count
            SendToChan .OnChannels.Item(x), .Prefix & " AutoKilled: Server Misconfigured", vbNullString
        Next x
        SendToServer "QUIT :AutoKilled: Server Misconfigured [see ircx.conf]", .Nick
        SendWsock .index, "KILL " & .Nick, ":AutoKilled: Server Misconfigured [see ircx.conf]", .Prefix
        m_error cptr, "Closing Link: (AutoKilled: Server Misconfigured [see ircx.conf])"
        ErrorMsg "The server is misconfigured. Please see ircx.conf."
        .IsKilled = True
        KillStruct .Nick
        Exit Function
    End If
    If OfflineMode = True Then
        If Len(OfflineMessage) = 0 Then
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
    SendWsock cptr.index, "PING " & pdat, vbNullString, , True
    IrcStat.UnknownConnections = IrcStat.UnknownConnections - 1
  End With
  Else
  With cptr
  For x = 1 To .OnChannels.Count
    SendToChan .OnChannels.Item(x), .Prefix & " AutoKilled: Illegal username -- change to an alphanumeric username.", vbNullString
    Next x
    SendToServer "QUIT :AutoKilled: Illegal username -- change to an alphanumeric username.", .Nick
    SendWsock .index, "KILL " & .Nick, ":AutoKilled: Illegal username -- change to an alphanumeric username.", .Prefix
    m_error cptr, "Closing Link: (AutoKilled: Illegal username -- change to an alphanumeric username.)"
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
If cptr.PassOK = True Then m_pass = 1: Exit Function

'for password-protected servers,
'and the link matches the protected I: line,
'links will need to have a special I:
'line for themselves, otherwise
'they'll have two different passwords
'which is a Bad Thing™

If Len(Trim(ILine(cptr.IIndex).Pass)) <> 0 Then
  Dim tmpPass As String
  If MD5Crypt = True Then
     tmpPass = oMD5.MD5(parv(0))
  Else
     tmpPass = parv(0)
  End If
  
  If StrComp(tmpPass, ILine(cptr.IIndex).Pass) = 0 Then
    m_pass = 1
    cptr.PassOK = True
    Exit Function
  Else
    m_pass = -1
    cptr.PassOK = False
    Exit Function
  End If
End If

'servers
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
        Case umLProtected
            If Not cptr.IsProtected = True Then
                cptr.IsLProtected = True
                add_umodes = add_umodes & CurMode
            End If
        Case umProtected
            If cptr.IsLProtected = True Then
                cptr.IsLProtected = False
            End If
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
    SendWsock cptr.index, ERR_NONICKNAMEGIVEN & " " & cptr.Nick, TranslateCode(ERR_NONICKNAMEGIVEN, , , "WHOWAS")
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

