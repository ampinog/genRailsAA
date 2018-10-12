ActiveSupport::Inflector.inflections(:en) do |inflect|
  inflect.plural(   /([aeo])$/i, '\1s'      )
  inflect.singular( /([aeo])s$/i, '\1'      )
  inflect.plural(   /([lnr])$/i, '\1es'     )
  inflect.singular( /([lnr])es$/i, '\1'     )
  inflect.irregular('version', 'versions'   )
end
