using HTTP

struct Citation
    # TODO: Replace by `SimpleBibTeX.jl`'s equivalent struct?
    s :: String
end
Base.show(io::IO, ::MIME"text/plain", c::Citation) = print(io, c.s)

# see https://discourse.julialang.org/t/replacing-citation-bib-with-a-standard-metadata-format/26871/4
# and the crossref API at https://citation.crosscite.org/docs.html
function _doi2bib(doi::AbstractString)
    doi = replace(doi, "http://" => "", "https://" => "", "doi.org/"=>"")
    return String(HTTP.get("https://doi.org/$doi",
                           ["Accept" => "application/x-bibtex"]).body)
end

function doi2bib(doi::AbstractString;
            minimal::Bool    = true, # remove unnecessary bibtex fields
            abbreviate::Bool = true  # abbreviate journal title
            )

    s = _doi2bib(doi)

    # TODO: Would be a ton better to do all these things with a dedicated BibTeX parser
    #       (the regex hacks don't really cut it; need a proper automata).
    #       Both Bibliography.jl and BibTeX.jl have awkward interfaces though: maybe just
    #       polish up /thchr/SimpleBibTeX.jl and use that?

    # remove unnecessary fields
    if minimal
        s = replace(s, r"\n\t(publisher|month|url) =.*" => "")
    end

    # change tabs to double-spaces
    s = replace(s, "\t" => "  ")

    # generate a better name for the entry
    firstword = _tryparse_first_word_of_title(s)
    doctype, author, year = _tryparse_doctype_author_year(s)
    s = replace(s, r"@\w+\{.*" => "@"*doctype*"{"*author*year*firstword*","; count=1)

    # abbreviate the journal title
    if abbreviate
        m = match(r"journal = \{(.+)\},?\n", s)
        if !isnothing(m)
            journal_name = something(m).captures[1]
            journal_abbr = journal_abbreviation(journal_name)
            s = replace(s, r"journal = \{.+\}(,?\n)" => 
                            SubstitutionString("journal = {"*journal_abbr*"}\\1"))
        end
    end

    return Citation(s)
end

function _tryparse_first_word_of_title(s)
    m = match(r"  title = \{(\w+)[\s|-]", s)
    m = match(r"  title = \{[\W|\s]?+(\w+)[\s|-]", s) # FIXME: ignore non-word starting titles
    # regex-approach is fragile (e.g., if 1st word starts with '{'): bail if unsuccesful
    return !isnothing(m) ? lowercase(something(m).captures[1]) : ""
end

function _tryparse_doctype_author_year(s)
    m = match(r"@(\w+)\{(\w+)_([0-9]+),", s)
    if !isnothing(m)
        return m.captures[1], lowercase(m.captures[2]), m.captures[3] # doctype, author, year
    else
        # try to parse individual entries to get desired information
        m??? = match(r"@(\w+)\{.*,\n", s)
        doctype = !isnothing(m???) ? m???.captures[1] : ""
        m??? = match(r"  (author|editor) = {(.+)},", s)
        author = if !isnothing(m???)
            firstauthor = split(m???.captures[2], " and ")[1]
            author = lowercase(split(firstauthor, isspace)[end])
        else
            "johndoe" # unknown author sentinel
        end
        m??? = match(r"  year = {?([0-9]*)}?", s)
        year = !isnothing(m???) ? m???.captures[1] : "0000" # unknown year sentinel
        
        return doctype, author, year
    end
end