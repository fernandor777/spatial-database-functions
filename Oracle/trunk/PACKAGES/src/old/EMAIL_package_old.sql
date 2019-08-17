DEFINE defaultSchema = '&1'
DEFINE mailServer    = 'mail.spatialdbadvisor.com'
ALTER SESSION SET plsql_optimize_level=1;

-- Adapted from asktom.oracle.com
-- NOTE: In XE need to GRANT access to UTL_SMTP to be able to use package (done in create_schema.sql)
--
create or replace package email
as
  type array         is table of varchar2(255);
  TYPE "STRINGARRAY" is table of varchar2(2048) ;
  c_from_email       varchar2(255) := 'db@mycompany.com';
  c_to_email         varchar2(255) := 'myaccount@mycompany.com';

  procedure send( p_sender_email in varchar2,
                  p_from         in varchar2    default NULL,
                  p_to           in stringarray default stringarray(),
                  p_cc           in stringarray default stringarray(),
                  p_bcc          in stringarray default stringarray(),
                  p_subject      in varchar2    default NULL,
                  p_body         in long        default NULL);
end;
/

create or replace package body email
as
  g_crlf        char(2) default chr(13)||chr(10);
  g_mail_conn   utl_smtp.connection;
  g_mailhost    varchar2(255) := '&mailServer.';

  -- Next we have an internal (unpublished) function to send an email to many
  -- recipients it in effect addresses the email.  At the same time, it builds the
  -- To: or Cc: lines that we?ll eventually send as part of the email itself and
  -- returns that formatted string.  It was implemented as a separate function since
  -- we need to do this separately for the To, CC, and BCC lists:
  --
  function address_email( p_string in varchar2,
                          p_recipients in stringarray )
  return varchar2
  is
    l_recipients long;
  begin
    for i in 1 .. p_recipients.count
    loop
       utl_smtp.rcpt(g_mail_conn, p_recipients(i) );
       if ( l_recipients is null )
       then
           l_recipients := p_string || p_recipients(i) ;
       else
           l_recipients := l_recipients || ', ' || p_recipients(i);
       end if;
    end loop;
    return l_recipients;
  end address_email;

  -- Now we have the implementation of our published function the one people will
  -- actually call to send mail.  It starts with an internal procedure writeData that
  -- is used to simplify the sending of the email headers (the To:, From:, Subject:
  -- records).  If the header record is NOT NULL, this routine will use the
  -- appropriate UTL_SMTP call to send it along with the necessary end of line
  -- marker (the carriage return/line feed):

  procedure send( p_sender_email in varchar2,
                  p_from         in varchar2    default NULL,
                  p_to           in stringarray default stringarray(),
                  p_cc           in stringarray default stringarray(),
                  p_bcc          in stringarray default stringarray(),
                  p_subject      in varchar2    default NULL,
                  p_body         in long        default NULL )
  is
    l_date      varchar2(255);

    procedure writeData( p_text in varchar2 )
    as
    begin
        if ( p_text is not null )
        then
            utl_smtp.write_data( g_mail_conn, p_text || g_crlf );
        end if;
    end writeData;

  -- Now we are ready to actually send the mail.  This part is not very different from
  -- the very simple routine we started with.  It begins in exactly the same fashion
  -- by connecting to the SMTP server and starting a session:

  begin
    begin
        select to_char(SYSTIMESTAMP, value,'NLS_DATE_LANGUAGE=' || (select value from nls_database_parameters where parameter='NLS_DATE_LANGUAGE') ) as send_date
          into l_date
          from nls_database_parameters 
         where parameter = 'NLS_TIMESTAMP_TZ_FORMAT';
        exception
           when others then
             l_date := to_char(SYSTIMESTAMP, 'Dy, dd Mon yyyy hh24:mi:ss tzhtzm','NLS_DATE_LANGUAGE=American');
    end;

    g_mail_conn := utl_smtp.open_connection(g_mailhost, 25);

    utl_smtp.helo(g_mail_conn, g_mailhost);
    utl_smtp.mail(g_mail_conn, p_sender_email);

    -- Now, we use the OPEN_DATA call to start sending the body of the email.
    utl_smtp.open_data(g_mail_conn );

    --  Generate the header section of data.
    writedata(    'From: ' || nvl( p_from, p_sender_email ) );
    writedata( address_email( 'To: ',  p_to ) );
    if ( p_cc is not null and p_cc.count > 0 ) then
       writedata( address_email( 'Cc: ',  p_cc ) );
    End If;
    if ( p_bcc is not null and p_bcc.count > 0 ) then
       writedata( address_email( 'Bcc: ', p_bcc ) );
    end if;
    writedata(    'Date: ' || l_date );
    writeData( 'Subject: ' || nvl( p_subject, '(no subject)' ) );

    utl_smtp.write_data( g_mail_conn, '' || g_crlf );
    -- send the body of the email (the contents of the email)
    utl_smtp.write_data(g_mail_conn, p_body );
    -- Terminate the email.
    utl_smtp.close_data(g_mail_conn );
    utl_smtp.quit(g_mail_conn);
  end send;
  
end EMAIL;
/
show errors

set serveroutput on size unlimited
WHENEVER SQLERROR EXIT FAILURE;
DECLARE
   v_OK       boolean := true;
   v_obj_name varchar2(30) := 'EMAIL';
BEGIN
   FOR rec IN (select object_name || '.' || object_Type as package_name, status 
                 from user_objects
                where object_name = v_obj_name) LOOP
      IF ( rec.status = 'VALID' ) Then
         dbms_output.put_line('Package ' || USER || '.' || rec.package_name || ' is valid.');
      ELSE
         dbms_output.put_line('Package ' || USER || '.' || rec.package_name || ' is invalid.');
         v_ok := false;
      END IF;
   END LOOP;
   IF ( NOT v_OK ) THEN
      RAISE_APPLICATION_ERROR(-20000,v_obj_name || ' failed to install.');
   END IF;
END;
/
SHOW ERRORS

grant execute on email to public;

QUIT;

/*
begin
  apex_mail.send(
    p_to => 'sgreener@netspace.net.au',
    p_from => 'simon@spatialdbadvisor.com',
    p_body => 'Hello wicked Hobittsssessss, '|| CHR(13) || CHR(10) || 'My precioussss Oracle UTL_SMTP and MAIL package works!'|| CHR(13) || CHR(10) || ' Gollum.'
  );
  apex_mail.push_queue;
end;
/

begin
   &defaultSchema..email.send
    ( p_sender_email => 'simon@spatialdbadvisor.com',
      p_from => 'simon@spatialdbadvisor.com',
      p_to => &defaultSchema..email.stringarray( 'sgreener@netspace.net.au' ),
      p_cc => &defaultSchema..email.stringarray( ),
      p_bcc => &defaultSchema..email.stringarray( ),
      p_subject => 'Test Email',
      p_body => 'Hello wicked Hobittsssessss, '|| CHR(13) || CHR(10) || 'My precioussss Oracle UTL_SMTP and MAIL package works!'|| CHR(13) || CHR(10) || ' Gollum.' );
end;
/
show errors
*/

