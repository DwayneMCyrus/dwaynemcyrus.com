
  document.querySelectorAll('.callout.foldable .callout-title').forEach(function(title) {
    title.addEventListener('click', function() {
      const callout = title.parentNode;
      callout.classList.toggle('folded');
    });
  });

