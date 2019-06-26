using System;
using System.Collections.Generic;
using System.Linq;
using System.Net.Mail;
using System.Text;
using System.Threading.Tasks;


public class MailSender
{
    public static string Send(string subject, string mailTo)
    {
        try
        {
            /*
            string subject = "Report Complite";
            string mailTo = "alex@russia.spb.ru";
            */
            string mailFrom = "robot@medline.spb.ru";
            System.Net.Mail.SmtpClient client = new SmtpClient("mx.russia.spb.ru");
            client.UseDefaultCredentials = false;
            client.Credentials = new System.Net.NetworkCredential("robot@russia.spb.ru", "somepassword");
            client.EnableSsl = false;
            client.DeliveryMethod = SmtpDeliveryMethod.Network;

            MailMessage mailMessage = new MailMessage(mailFrom, mailTo);
            mailMessage.Subject = subject;
            mailMessage.Body = "Отчет сгенерирован";
            client.Send(mailMessage);
            return "OK";
        }
        catch (Exception ex)
        {
            return ex.Message;
        }
    }

}

