require 'cgi'
require 'uri'

class PetitionPrintService

  attr_accessor :context,
                :link_color,
                :number_of_columns,
                :pdf,
                :petition,
                :text_color

  def initialize(context, pdf, petition)
    self.context = context
    self.link_color = '286BCC'
    self.number_of_columns = 3
    self.petition = petition
    self.pdf = pdf
    self.text_color = '444444'
  end

  def render
    # Civic Commons logo
    pdf.image "#{RAILS_ROOT}/public/images/cc_logo_300dpi.png", :scale => 0.1

    # today's date
    pdf.move_up 5
    pdf.text "As of #{ date_string(Date.today) }", align: :right, color: text_color, size: 10

    # horizontal line
    pdf.stroke do
      pdf.horizontal_rule
    end

    # petition title
    pdf.move_down 20
    pdf.formatted_text [
      { text: petition.title, size: 20, color: text_color, style: :bold }
    ]

    # petition creator info
    pdf.move_down 5
    pdf.formatted_text [
      { text: "Written by: ", color: text_color },
      { text: petition.person.name, color: link_color, link: context.user_url(petition.person) },
      { text: " on #{ date_string(petition.created_at) }", color: text_color }
    ]

    # petition description
    pdf.move_down 10
    matches = petition.description.scan(/<p>(.+?)<\/p>/m)
    matches.each do |paragraph|
      pdf.text CGI.unescapeHTML(paragraph[0]), color: text_color, size: 12
      pdf.move_down 10
    end

    # today's date
    pdf.move_down 20
    pdf.text "#{ petition.signer_ids.count } Signatures", color: text_color, size: 10, style: :bold

    # horizontal line
    pdf.stroke do
      pdf.horizontal_rule
    end

    # column for user names/avatars
    pdf.move_down 15

    # output petition signers or a message if no signers
    if petition.signatures.length == 0
      pdf.text "There have been no signatures so far.", color: text_color
    else
      signature_table.draw()
    end
  end

  private

  def date_string(date)
    date.strftime('%b %d, %Y')
  end

  def signer_text_data(name, signature_date)
    [
      [name],
      ["#{ date_string(signature_date) } (date signed)"]
    ]
  end

  def signer_text_table(signature)
    signer = signature.person
    pdf.make_table(signer_text_data(signer.name, signature.created_at), cell_style: { text_color: text_color }, width: 140) do
      cells.borders = []
      cells.size = 10
      row(0).font_style = :bold
      row(0).padding = [0, 15, 0, 0]
      row(1).padding = [2, 15, 10, 0]
    end
  end

  def signature_data(signature)
    [
      {
        image: open(URI.escape(AvatarService.avatar_image_url(signature.person))),
        scale: 0.4
      },
      signer_text_table(signature)
    ]
  end

  def signature_table
    data = []
    row = []
    petition.signatures.each_with_index do |signature, index|
      if index % self.number_of_columns == 0
        row = []
      end

      values = signature_data(signature)
      for value in values
        row.push(value)
      end

      if (index % self.number_of_columns == self.number_of_columns - 1) or
        (petition.signatures.length == index + 1)
        data.push(row)
      end
    end

    pdf.make_table(data) do
      cells.borders = []
      columns((0..(data.first.length * 2)).step(2)).padding = 0
      columns((0..(data.first.length * 2)).step(2)).width = 40
    end
  end
end