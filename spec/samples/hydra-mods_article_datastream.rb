module Hydra
  # This is an example of a OmDatastream that defines an OM terminology for MODS xml
  # It focuses on the aspects of MODS that deal with descriptive metadata for published articles
  # This is not the hydra-head plugin version of this OM Terminology; See https://github.com/projecthydra/hydra-head/blob/master/lib/hydra/mods_article.rb
  #
  # Things to note about the OM Terminology defined here:
  #
  # * Uses :ref terms to repeat the structures of a mods:name with a different @type on the mods:name element
  # * Defines a term lang_code that maps to "languageTerm[@type=code]"
  # * Defines a variety of terms, date, last_name, first_name & terms_of_address, that all map to mods:namePart but use varying attributes to distinguish themselves
  # * Uses proxy terms to define familar terms like start_page and end_page that map to non-intuitive xml structures "extent[@unit=pages]/start" and "extent[@unit=pages]/end"
  # * Uses proxy terms, publication_url, peer_reviewed, and title, to allow convenient access to frequently used terms
  #
  # Things to note about the additional methods it defines:
  #
  # * Defines a series of templates, person_template, organization_template, etc. for generating a whole set of xml nodes to insert into the document (note: the new OM::TemplateRegistry provides an even better way to do this)
  # * Defines a custom method, insert_contributor, that uses the Terminology to manipulate xml documents in specialized ways
  # * Defines a series of relator_term Hashes that can then be used when generating views, etc.  In this case, the Hashes are hard-coded into the Class.  Ideally, they might be read from a configuration file or mixed into the class using a module
  class ModsArticleDatastream < ActiveFedora::OmDatastream
    set_terminology do |t|
      t.root(path: "mods", xmlns: "http://www.loc.gov/mods/v3", schema: "http://www.loc.gov/standards/mods/v3/mods-3-2.xsd")

      t.title_info(path: "titleInfo") {
        t.main_title(index_as: [:facetable], path: "title", label: "title")
        t.language(index_as: [:facetable], path: { attribute: "lang" })
      }
      t.language {
        t.lang_code(index_as: [:facetable], path: "languageTerm", attributes: { type: "code" })
      }
      t.abstract
      t.subject {
        t.topic(index_as: [:facetable])
      }
      t.topic_tag(proxy: [:subject, :topic])
      # t.topic_tag(:index_as=>[:facetable],:path=>"subject", :default_content_path=>"topic")
      # This is a mods:name.  The underscore is purely to avoid namespace conflicts.
      t.name_(index_as: [:searchable]) {
        # this is a namepart
        t.namePart(type: :string, label: "generic name")
        # affiliations are great
        t.affiliation
        t.institution(path: "affiliation", index_as: [:facetable], label: "organization")
        t.displayForm
        t.role(ref: [:role])
        t.description(index_as: [:facetable])
        t.date(path: "namePart", attributes: { type: "date" })
        t.last_name(path: "namePart", attributes: { type: "family" })
        t.first_name(path: "namePart", attributes: { type: "given" }, label: "first name")
        t.terms_of_address(path: "namePart", attributes: { type: "termsOfAddress" })
        t.computing_id
      }
      # lookup :person, :first_name
      t.person(ref: :name, attributes: { type: "personal" }, index_as: [:facetable, :stored_searchable])
      t.department(proxy: [:person, :description], index_as: [:facetable])
      t.organization(ref: :name, attributes: { type: "corporate" }, index_as: [:facetable])
      t.conference(ref: :name, attributes: { type: "conference" }, index_as: [:facetable])
      t.role(index_as: [:stored_searchable]) {
        t.text(path: "roleTerm", attributes: { type: "text" }, index_as: [:stored_searchable])
        t.code(path: "roleTerm", attributes: { type: "code" })
      }
      t.journal(path: 'relatedItem', attributes: { type: "host" }) {
        t.title_info(index_as: [:facetable], ref: [:title_info])
        t.origin_info(path: "originInfo") {
          t.publisher
          t.date_issued(path: "dateIssued")
          t.issuance(index_as: [:facetable])
        }
        t.issn(path: "identifier", attributes: { type: "issn" })
        t.issue(path: "part") {
          t.volume(path: "detail", attributes: { type: "volume" }, default_content_path: "number")
          t.level(path: "detail", attributes: { type: "number" }, default_content_path: "number")
          t.extent
          t.pages(path: "extent", attributes: { unit: "pages" }) {
            t.start
            t.end
          }
          t.start_page(proxy: [:pages, :start])
          t.end_page(proxy: [:pages, :end])
          t.publication_date(path: "date", type: :date, index_as: [:stored_searchable])
        }
      }
      t.note
      t.location(path: "location") {
        t.url(path: "url")
      }
      t.publication_url(proxy: [:location, :url])
      t.peer_reviewed(proxy: [:journal, :origin_info, :issuance], index_as: [:facetable])
      t.title(proxy: [:title_info, :main_title])
      t.journal_title(proxy: [:journal, :title_info, :main_title])
    end

    # Generates an empty Mods Article (used when you call ModsArticle.new without passing in existing xml)
    def self.xml_template
      builder = Nokogiri::XML::Builder.new do |xml|
        xml.mods(:version => "3.3", "xmlns:xlink" => "http://www.w3.org/1999/xlink",
                 "xmlns:xsi" => "http://www.w3.org/2001/XMLSchema-instance",
                 "xmlns" => "http://www.loc.gov/mods/v3",
                 "xsi:schemaLocation" => "http://www.loc.gov/mods/v3 http://www.loc.gov/standards/mods/v3/mods-3-3.xsd") {
          xml.titleInfo(lang: "") {
            xml.title
          }
          xml.name(type: "personal") {
            xml.namePart(type: "given")
            xml.namePart(type: "family")
            xml.affiliation
            xml.computing_id
            xml.description
            xml.role {
              xml.roleTerm("Author", authority: "marcrelator", type: "text")
            }
          }
          xml.typeOfResource
          xml.genre(authority: "marcgt")
          xml.language {
            xml.languageTerm(authority: "iso639-2b", type: "code")
          }
          xml.abstract
          xml.subject {
            xml.topic
          }
          xml.relatedItem(type: "host") {
            xml.titleInfo {
              xml.title
            }
            xml.identifier(type: "issn")
            xml.originInfo {
              xml.publisher
              xml.dateIssued
              xml.issuance
            }
            xml.part {
              xml.detail(type: "volume") {
                xml.number
              }
              xml.detail(type: "number") {
                xml.number
              }
              xml.extent(unit: "pages") {
                xml.start
                xml.end
              }
              xml.date
            }
          }
          xml.location {
            xml.url
          }
        }
      end
      builder.doc
    end

    def prefix(name)
      "#{name.underscore}__"
    end

    # Generates a new Person node
    def self.person_template
      builder = Nokogiri::XML::Builder.new do |xml|
        xml.name(type: "personal") {
          xml.namePart(type: "family")
          xml.namePart(type: "given")
          xml.affiliation
          xml.computing_id
          xml.description
          xml.role {
            xml.roleTerm("Author", type: "text")
          }
        }
      end
      builder.doc.root
    end

    def self.full_name_template
      builder = Nokogiri::XML::Builder.new do |xml|
        xml.full_name(type: "personal")
      end
      builder.doc.root
    end

    # Generates a new Organization node
    # Uses mods:name[@type="corporate"]
    def self.organization_template
      builder = Nokogiri::XML::Builder.new do |xml|
        xml.name(type: "corporate") {
          xml.namePart
          xml.role {
            xml.roleTerm(authority: "marcrelator", type: "text")
          }
        }
      end
      builder.doc.root
    end

    # Generates a new Conference node
    def self.conference_template
      builder = Nokogiri::XML::Builder.new do |xml|
        xml.name(type: "conference") {
          xml.namePart
          xml.role {
            xml.roleTerm(authority: "marcrelator", type: "text")
          }
        }
      end
      builder.doc.root
    end

    # Inserts a new contributor (mods:name) into the mods document
    # creates contributors of type :person, :organization, or :conference
    def insert_contributor(type, _opts = {})
      case type.to_sym
      when :person
        node = Hydra::ModsArticleDatastream.person_template
        nodeset = find_by_terms(:person)
      when :organization
        node = Hydra::ModsArticleDatastream.organization_template
        nodeset = find_by_terms(:organization)
      when :conference
        node = Hydra::ModsArticleDatastream.conference_template
        nodeset = find_by_terms(:conference)
      else
        ActiveFedora.logger.warn("#{type} is not a valid argument for Hydra::ModsArticleDatastream.insert_contributor")
        node = nil
        index = nil
      end

      unless nodeset.nil?
        if nodeset.empty?
          ng_xml.root.add_child(node)
          index = 0
        else
          nodeset.after(node)
          index = nodeset.length
        end
        self.dirty = true
      end

      [node, index]
    end

    # Remove the contributor entry identified by @contributor_type and @index
    def remove_contributor(contributor_type, index)
      find_by_terms(contributor_type.to_sym => index.to_i).first.remove
      self.dirty = true
    end

    def self.common_relator_terms
      { "aut" => "Author",
        "clb" => "Collaborator",
        "com" => "Compiler",
        "ctb" => "Contributor",
        "cre" => "Creator",
        "edt" => "Editor",
        "ill" => "Illustrator",
        "oth" => "Other",
        "trl" => "Translator" }
    end

    def self.person_relator_terms
      { "aut" => "Author",
        "clb" => "Collaborator",
        "com" => "Compiler",
        "cre" => "Creator",
        "ctb" => "Contributor",
        "edt" => "Editor",
        "ill" => "Illustrator",
        "res" => "Researcher",
        "rth" => "Research team head",
        "rtm" => "Research team member",
        "trl" => "Translator" }
    end

    def self.conference_relator_terms
      {
        "hst" => "Host"
      }
    end

    def self.organization_relator_terms
      {
        "fnd" => "Funder",
        "hst" => "Host"
      }
    end

    def self.dc_relator_terms
      { "acp" => "Art copyist",
        "act" => "Actor",
        "adp" => "Adapter",
        "aft" => "Author of afterword, colophon, etc.",
        "anl" => "Analyst",
        "anm" => "Animator",
        "ann" => "Annotator",
        "ant" => "Bibliographic antecedent",
        "app" => "Applicant",
        "aqt" => "Author in quotations or text abstracts",
        "arc" => "Architect",
        "ard" => "Artistic director ",
        "arr" => "Arranger",
        "art" => "Artist",
        "asg" => "Assignee",
        "asn" => "Associated name",
        "att" => "Attributed name",
        "auc" => "Auctioneer",
        "aud" => "Author of dialog",
        "aui" => "Author of introduction",
        "aus" => "Author of screenplay",
        "aut" => "Author",
        "bdd" => "Binding designer",
        "bjd" => "Bookjacket designer",
        "bkd" => "Book designer",
        "bkp" => "Book producer",
        "bnd" => "Binder",
        "bpd" => "Bookplate designer",
        "bsl" => "Bookseller",
        "ccp" => "Conceptor",
        "chr" => "Choreographer",
        "clb" => "Collaborator",
        "cli" => "Client",
        "cll" => "Calligrapher",
        "clt" => "Collotyper",
        "cmm" => "Commentator",
        "cmp" => "Composer",
        "cmt" => "Compositor",
        "cng" => "Cinematographer",
        "cnd" => "Conductor",
        "cns" => "Censor",
        "coe" => "Contestant -appellee",
        "col" => "Collector",
        "com" => "Compiler",
        "cos" => "Contestant",
        "cot" => "Contestant -appellant",
        "cov" => "Cover designer",
        "cpc" => "Copyright claimant",
        "cpe" => "Complainant-appellee",
        "cph" => "Copyright holder",
        "cpl" => "Complainant",
        "cpt" => "Complainant-appellant",
        "cre" => "Creator",
        "crp" => "Correspondent",
        "crr" => "Corrector",
        "csl" => "Consultant",
        "csp" => "Consultant to a project",
        "cst" => "Costume designer",
        "ctb" => "Contributor",
        "cte" => "Contestee-appellee",
        "ctg" => "Cartographer",
        "ctr" => "Contractor",
        "cts" => "Contestee",
        "ctt" => "Contestee-appellant",
        "cur" => "Curator",
        "cwt" => "Commentator for written text",
        "dfd" => "Defendant",
        "dfe" => "Defendant-appellee",
        "dft" => "Defendant-appellant",
        "dgg" => "Degree grantor",
        "dis" => "Dissertant",
        "dln" => "Delineator",
        "dnc" => "Dancer",
        "dnr" => "Donor",
        "dpc" => "Depicted",
        "dpt" => "Depositor",
        "drm" => "Draftsman",
        "drt" => "Director",
        "dsr" => "Designer",
        "dst" => "Distributor",
        "dtc" => "Data contributor ",
        "dte" => "Dedicatee",
        "dtm" => "Data manager ",
        "dto" => "Dedicator",
        "dub" => "Dubious author",
        "edt" => "Editor",
        "egr" => "Engraver",
        "elg" => "Electrician ",
        "elt" => "Electrotyper",
        "eng" => "Engineer",
        "etr" => "Etcher",
        "exp" => "Expert",
        "fac" => "Facsimilist",
        "fld" => "Field director ",
        "flm" => "Film editor",
        "fmo" => "Former owner",
        "fpy" => "First party",
        "fnd" => "Funder",
        "frg" => "Forger",
        "gis" => "Geographic information specialist ",
        "grt" => "Graphic technician",
        "hnr" => "Honoree",
        "hst" => "Host",
        "ill" => "Illustrator",
        "ilu" => "Illuminator",
        "ins" => "Inscriber",
        "inv" => "Inventor",
        "itr" => "Instrumentalist",
        "ive" => "Interviewee",
        "ivr" => "Interviewer",
        "lbr" => "Laboratory ",
        "lbt" => "Librettist",
        "ldr" => "Laboratory director ",
        "led" => "Lead",
        "lee" => "Libelee-appellee",
        "lel" => "Libelee",
        "len" => "Lender",
        "let" => "Libelee-appellant",
        "lgd" => "Lighting designer",
        "lie" => "Libelant-appellee",
        "lil" => "Libelant",
        "lit" => "Libelant-appellant",
        "lsa" => "Landscape architect",
        "lse" => "Licensee",
        "lso" => "Licensor",
        "ltg" => "Lithographer",
        "lyr" => "Lyricist",
        "mcp" => "Music copyist",
        "mfr" => "Manufacturer",
        "mdc" => "Metadata contact",
        "mod" => "Moderator",
        "mon" => "Monitor",
        "mrk" => "Markup editor",
        "msd" => "Musical director",
        "mte" => "Metal-engraver",
        "mus" => "Musician",
        "nrt" => "Narrator",
        "opn" => "Opponent",
        "org" => "Originator",
        "orm" => "Organizer of meeting",
        "oth" => "Other",
        "own" => "Owner",
        "pat" => "Patron",
        "pbd" => "Publishing director",
        "pbl" => "Publisher",
        "pdr" => "Project director",
        "pfr" => "Proofreader",
        "pht" => "Photographer",
        "plt" => "Platemaker",
        "pma" => "Permitting agency",
        "pmn" => "Production manager",
        "pop" => "Printer of plates",
        "ppm" => "Papermaker",
        "ppt" => "Puppeteer",
        "prc" => "Process contact",
        "prd" => "Production personnel",
        "prf" => "Performer",
        "prg" => "Programmer",
        "prm" => "Printmaker",
        "pro" => "Producer",
        "prt" => "Printer",
        "pta" => "Patent applicant",
        "pte" => "Plaintiff -appellee",
        "ptf" => "Plaintiff",
        "pth" => "Patent holder",
        "ptt" => "Plaintiff-appellant",
        "rbr" => "Rubricator",
        "rce" => "Recording engineer",
        "rcp" => "Recipient",
        "red" => "Redactor",
        "ren" => "Renderer",
        "res" => "Researcher",
        "rev" => "Reviewer",
        "rps" => "Repository",
        "rpt" => "Reporter",
        "rpy" => "Responsible party",
        "rse" => "Respondent-appellee",
        "rsg" => "Restager",
        "rsp" => "Respondent",
        "rst" => "Respondent-appellant",
        "rth" => "Research team head",
        "rtm" => "Research team member",
        "sad" => "Scientific advisor",
        "sce" => "Scenarist",
        "scl" => "Sculptor",
        "scr" => "Scribe",
        "sds" => "Sound designer",
        "sec" => "Secretary",
        "sgn" => "Signer",
        "sht" => "Supporting host",
        "sng" => "Singer",
        "spk" => "Speaker",
        "spn" => "Sponsor",
        "spy" => "Second party",
        "srv" => "Surveyor",
        "std" => "Set designer",
        "stl" => "Storyteller",
        "stm" => "Stage manager",
        "stn" => "Standards body",
        "str" => "Stereotyper",
        "tcd" => "Technical director",
        "tch" => "Teacher",
        "ths" => "Thesis advisor",
        "trc" => "Transcriber",
        "trl" => "Translator",
        "tyd" => "Type designer",
        "tyg" => "Typographer",
        "vdg" => "Videographer",
        "voc" => "Vocalist",
        "wam" => "Writer of accompanying material",
        "wdc" => "Woodcutter",
        "wde" => "Wood -engraver",
        "wit" => "Witness" }
    end

    def self.valid_child_types
      ["data", "supporting file", "profile", "lorem ipsum", "dolor"]
    end

    def to_solr(solr_doc = {}, opts = {})
      solr_doc = super

      ::Solrizer::Extractor.insert_solr_field_value(solr_doc, ActiveFedora.index_field_mapper.solr_name('object_type', :facetable), "Article")
      ::Solrizer::Extractor.insert_solr_field_value(solr_doc, ActiveFedora.index_field_mapper.solr_name('mods_journal_title_info', :facetable), "Unknown") if solr_doc["mods_journal_title_info_facet"].nil?

      solr_doc
    end
  end
end
