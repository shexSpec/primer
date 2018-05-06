$(function () {
  var bodyKeypressCallbacks = {};

  /* a form like
     <form id="langOptions" action="">View as: <input type="radio" name="presLang" value="turtle" checked="checked">ShExC (press 'c')</input> <input type="radio" name="presLang" value="json">JSON (press 'j')</input> .</form>
     controls display of sections like
     <pre class="nohighlight schema shexc">...</pre>
     <pre class="nohighlight schema json">...</pre>
  */
  [
    { lookIn: ".schema", form: "#langOptions", radioName: "presLang", keys:
      { 74: "json", 106: "json", 67: "shexc", 99: "shexc" }
    }
  ].forEach(function (x) {

    /* In lookIn, reveal classes selected by radioName; hide others.
     */
    function revealClass (lookIn, form, radioName) {
      $(lookIn+"."+$(form+" input[name="+radioName+"]").not(":checked").val()).hide();
      $(lookIn+"."+$(form+" input[name="+radioName+"]" +    ":checked").val()).show();
    }
    /* Look in all lookIn containers for the height different of from and to targets.
     */
    function adjustHeight (lookIn, from, to) {
      var visibleTop = $(window).scrollTop();
      var all = $(lookIn+"."+from); // all containers of from (and presumably, to)
      var adj = 0;
      for (var i = 0; i < all.length; ++i) {
        var elt = all.slice(i, i+1);
        if (elt.offset().top >= visibleTop) // stop when we pass the current scroll top.
          break;
        adj += elt.siblings("."+to).height() - elt.height();
      }
      $(window).scrollTop($(window).scrollTop() + adj); // move the scroll top.
    }

    var inputs = $(x.form + " input[name="+x.radioName+"]");
    // Listen for checkbox changes.
    inputs.change(function() {revealClass(x.lookIn, x.form, x.radioName);})
    // Show only the currently selected class.
    revealClass(x.lookIn, x.form, x.radioName);
    // Assign callbacks the the associated keycodes.
    Object.keys(x.keys).forEach(function (k) {
      bodyKeypressCallbacks[k] = function () {
        var sourceClass = $("input[name="+x.radioName+"]:checked", x.form).val();
        var targetClass = x.keys[k];
        // If the corresponding radio button isn't already selected,
        if(!inputs.filter("[value="+targetClass+"]").is(":checked")) {
          // adjust the height from the current class to the new class;
          adjustHeight(x.lookIn, sourceClass, targetClass);
          // set it as "checked";
          inputs.filter("[value="+targetClass+"]").prop("checked", true); // .change() did nothing
          // swap which is displayed.
          revealClass(x.lookIn, x.form, x.radioName);
          updateAllTryItLinks(targetClass);
        }
        return false;
      };
    });
  });
  $("html > body").keypress(function (evt) {
    if (evt.ctrlKey)
      return true; // don't interfere with browser control keys.
    if (evt.which in bodyKeypressCallbacks)
      return bodyKeypressCallbacks[evt.which]();
    return true;
  });
  Interfaces = [
    // { label: "local",
    //   link: "http://localhost/shexSpec/shex.js/doc/shex-simple.html?" },
    { label: "js", name: "shex.js",
      link: "http://rawgit.com/shexSpec/shex.js/on-shape-expression/doc/shex-simple.html?" },
    { label: "scala", name: "rdfshape",
      link: "http://rdfshape.weso.es/validate?triggerMode=ShapeMap&" }
  ];
  FaveInterface = null;

  var pickDefaultValidator_form = $("#defaultValidator-form");
  var pickDefaultValidator_dialog;
  
  Interfaces.forEach(
    iface => pickDefaultValidator_form.find("fieldset").append(
      $("<input/>", {type: "radio", name: "fave", id: "select-"+iface.label, value: iface.label}),
      $("<label/>", {for: "select-"+iface.label, title: iface.link}).append(
        iface.label + ' - ' + iface.name,
        $("<br/>"),
        iface.link,
      ),
      $("<br/>"),
    )
  )

  window.addEventListener("load", function() {
    setTimeout(() => { // respecIsReady not defined during this event cycle in Chrome.
      document.respecIsReady.then(function(conf) {
        console.log("Fix Try It links");
        updateAllTryItLinks($("#langOptions input:checked").val());
      });
    }, 3000);
  });

  pickDefaultValidator_dialog = $( "#defaultValidator-form" ).dialog({
    autoOpen: false,
    modal: true,
    width: "auto",
    buttons: {
      "Update": function(evt) {
        $("#faveInterface").text(FaveInterface = $('input[name=fave]:checked').val());
        pickDefaultValidator_dialog.dialog( "close" );
        validate(evt);
        return true;
      },
      Cancel: function(evt) {
        pickDefaultValidator_dialog.dialog( "close" );
      }
    }
  });
  
  $( ".tryit" ).button().on( "click", function(evt) {
    console.log(evt);
    if (FaveInterface && !evt.ctrlKey)
      validate(evt);
    else
      pickDefaultValidator_dialog.dialog( "open" );
  });

  function validate () {
    window.location.replace(FaveInterface + [
              "interface=minimal",
              "schema=" + encodeURIComponent(schema),
              "data=" + encodeURIComponent(data),
              "shape-map=" + encodeURIComponent(span.attr("data-shape-map"))
            ].join("&"))
  }

  function updateAllTryItLinks (schemaClass) {
    $(".tryit").map((idx, elt) => { updateTryItLink($(elt), schemaClass); })
  }
  function updateTryItLink (span, schemaClass) {
    debugger
    // var schemaElt = $(span.attr("href") + " ." + schemaClass);
    var schemaElt = span.parent().parent().find("."+schemaClass);
    var schema = schemaElt.text().replace(/^#.*?\n/, "");
    var data = span.parent().text();
    data = data.replace(/^\n +/, ""); // remove trailing spaces in data
    span.append(
      Interfaces.reduce(
        (toAdd, iface, idx) => toAdd.concat(
          (idx === 0 ? "try it: " : " | "),
          $("<a/>", {
            href: iface.link + [
              "interface=minimal",
              "schema=" + encodeURIComponent(schema),
              "data=" + encodeURIComponent(data),
              "shape-map=" + encodeURIComponent(span.attr("data-shape-map"))
            ].join("&")
          }).text(iface.label),
        ), []
      )
    );
  }
})()


