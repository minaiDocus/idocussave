CKEDITOR.addTemplates("my_templates",
{
  imagesPath:CKEDITOR.getUrl(CKEDITOR.plugins.getPath("templates")+"templates/images/"),

  templates:
  [
    {
      title: 'Cabinet & iDocus',
      description: "Rappelez aux clients de nous envoyer leurs documents. Les informations entre crochés double vont être modifiées à l'envoi du mail, tandis que celles en gras sont à modifier." ,
      html:
        "<div style='font-family:arial'>" +
        "Bonjour [[nom du client]],</br>" +
        "</br>" +
        "Vous bénéficiez du service proposé par [[nom du cabinet]] et iDocus pour la dématérialisation de vos pièces comptables.</br>" +
        "</br>" +
        "Nous vous remercions de nous les envoyer au plus vite afin que nous puissions les traiter dès que possible.</br>" +
        "</br>" +
        "Ne tenez pas compte de ce message si vous venez d'effectuer votre envoi.</br>" +
        "</br>" +
        "Si vous avez des questions sur l'utilisation de ce service, n'hésitez pas à les poser à votre cabinet d’expertise comptable à l’adresse <b>adresse email du cabinet</b> ou à iDocus à l’adresse <a href='mailto:support@idocus.com'>support@idocus.com</a>.</br>" +
        "</br>" +
        "Cordialement,</br>" +
        "</br>" +
        "L'équipe iDocus.</div>"
    },
    {
      title: 'Cabinet',
      description: "Rappelez aux clients de nous envoyer leurs documents. Les informations entre crochés double vont être modifiées à l'envoie du mail, tandis que celle en gras sont à modifier." ,
      html:
        "<div style='font-family:arial'>" +
        "Bonjour [[nom du client]],</br>" +
        "</br>" +
        "Vous bénéficiez du service proposé par [[nom du cabinet]] pour la dématérialisation de vos pièces comptables.</br>" +
        "</br>" +
        "Nous vous remercions de nous les envoyer au plus vite afin que nous puissions les traiter dès que possible.</br>" +
        "</br>" +
        "Ne tenez pas compte de ce message si vous venez d'effectuer votre envoi.</br>" +
        "</br>" +
        "Si vous avez des questions sur l'utilisation de ce service, n'hésitez pas à les poser à votre cabinet d’expertise comptable à l’adresse <b>adresse email du cabinet</b>.</br>" +
        "</br>" +
        "Cordialement,</br>" +
        "</br>" +
        "L'équipe [[nom du cabinet]].</div>"
    }
  ]
});
