class ContactsController < ApplicationController
  before_action :authenticate_user!, except: %i[new create]
  before_action :set_contact, only: %i[show destroy]

  # GET /contacts
  # GET /contacts.json
  def index
    @contacts = Contact.all
  end

  # GET /contacts/1
  # GET /contacts/1.json
  def show
  end

  # GET /contacts/new
  def new
    @contact = Contact.new
  end

  # POST /contacts
  # POST /contacts.json

  def create
    @contact = Contact.new(contact_params)
    respond_to do |format|
      if verify_recaptcha(model: @contact)
        if @contact.save
          @contact = Contact.new
          format.html do
            render :new,
                   locals: {
                     notice:
                       "Mensaje guardado! Recibirá nuestra respuesta en breve."
                   }
          end
        else
          format.html { render :new }
        end
      else
        format.html { render :new }
      end
    end
  end

  # DELETE /contacts/1.json
  def destroy
    @contact.destroy
    respond_to do |format|
      format.html do
        redirect_to contacts_url, notice: "Contact was successfully destroyed."
      end
      format.json { head :no_content }
    end
  end

  def clean
    Contact.destroy_all
    respond_to do |format|
      format.html do
        redirect_to contacts_url, notice: "Contact messages deleted."
      end
      format.json { head :no_content }
    end
  end

  private

  # Use callbacks to share common setup or constraints between actions.
  def set_contact
    @contact = Contact.find(params[:id])
  end

  # Never trust parameters from the scary internet, only allow the white list through.
  def contact_params
    params.require(:contact).permit(:name, :email, :message)
  end
end
