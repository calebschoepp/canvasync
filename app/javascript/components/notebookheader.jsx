import React, { useCallback } from 'react';

export const NotebookHeader = () => {

  const handleCopyButtonCallback = useCallback((event) => {
    const copyUrl = window.location.href + '/preview';
    navigator.clipboard.writeText(copyUrl).then(() => {
      event.target.classList.add('copied');
      const copiedNotificationTimeout = setInterval(() => {
        event.target.classList.remove('copied');
        clearInterval(copiedNotificationTimeout);
      }, 600);
    }, () => {
      /* clipboard write failed */
    });
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
