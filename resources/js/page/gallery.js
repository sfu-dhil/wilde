(function ($) {
    $(document).ready(function () {
        
        $('#imgModal').on('show.bs.modal', function (event) {
            var $button = $(event.relatedTarget);
            // Button that triggered the modal
            var $modal = $(this);
            
            $modal.find('#modalTitle').text($button.data('title'));
            $modal.find('figcaption').html($button.parent().parent().find('.caption').clone());
            $modal.find("#modalImage").attr('src', $button.data('img'));
        })
    });
})(jQuery);
