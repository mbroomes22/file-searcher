import React, { useState } from 'react';

function CsvUploader() {
    const [selectedFile, setSelectedFile] = useState(null);
    const [uploadStatus, setUploadStatus] = useState('');
    const [uploadId, setUploadId] = useState(null);


const handleFileChange = (event) => {
    setSelectedFile(event.target.files[0]);
}

const handleUpload = async () => {
    if (!selectedFile) {
        setUploadStatus('Please select a file.');
        return;
    }
}

const formData = new FormData();
formData.append('csv_upload[file]', selectedFile);

try {
  const response = await fetch('/csv_uploads', {
    method: 'POST',
    body: formData,
  });

  const data = await response.json();
  setUploadStatus(`Upload started. ID: ${data.id}`);
  setUploadId(data.id);
  checkStatus(data.id); // Start polling
} catch (error) {
  setUploadStatus(`Upload failed: ${error.message}`);
}
};

const checkStatus = async (id) => {
const interval = setInterval(async () => {
  try {
    const response = await fetch(`/csv_uploads/${id}`);
    const data = await response.json();
    setUploadStatus(`Status: ${data.status}`);

    if (data.status === 'completed' || data.status === 'failed') {
      clearInterval(interval);
      if (data.processed_file_url) {
        setUploadStatus(
            <>
            Status: completed. 
            <a href={data.processed_file_url}>
                Download Processed CSV
            </a>
            </>
        )
      }
    } 
    else if (data.status === 'failed') {
        clearInterval(interval)
    }
  } catch (error) {
    setUploadStatus(`Error checking status: ${error.message}`);
    clearInterval(interval);
  }
}, 2000); // Check every 2 seconds


return (
<div>
  <input type="file" onChange={handleFileChange} accept=".csv" />
  <button onClick={handleUpload}>Upload CSV</button>
  <p>{uploadStatus}</p>
</div>
);
}

export default CsvUploader;