import React, { useCallback } from 'react';

// This component contains presentational functionality
export const NotebookHeader = () => {
  const handleCopyButtonCallback = useCallback((event) => {
    const copyUrl = window.location.href + '/preview';
    if (navigator.clipboard && window.isSecureContext) {
      navigator.clipboard.writeText(copyUrl).then(() => {
        event.target.classList.add('copied');
        const copiedNotificationTimeout = setInterval(() => {
          event.target.classList.remove('copied');
          clearInterval(copiedNotificationTimeout);
        }, 600);
      }, () => {
        /* clipboard write failed */
      });
    } else {
      const textArea = document.createElement("textarea");
      textArea.value = copyUrl;
      // make the textarea out of viewport
      textArea.style.position = "fixed";
      textArea.style.left = "-999999px";
      textArea.style.top = "-999999px";
      document.body.appendChild(textArea);
      textArea.focus();
      textArea.select();
      return new Promise((res, rej) => {
        // here the magic happens
        document.execCommand('copy') ? res() : rej();
        textArea.remove();
        event.target.classList.add('copied');
        const copiedNotificationTimeout = setInterval(() => {
          event.target.classList.remove('copied');
          clearInterval(copiedNotificationTimeout);
        }, 600);
      });
    }
  });

  return (
    <>
      <h1 className="heading-1 mx-auto">{window.notebookName}</h1>
      <div className='flex flex-row justify-around w-full items-center'>
        <h2 className="heading-3">{`Notebook Share ID: ${window.notebookId}`}</h2>
        <button className='secondary-button' onClick={handleCopyButtonCallback}>
          Copy Share Link<span className='text-gray-700 copied-notification'>Copied</span>
        </button>
      </div>
    </>
  );

};
