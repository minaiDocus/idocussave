window.onload = () ->
  ios_users = parseInt($('#ios_users').val())
  android_users = parseInt($('#android_users').val())
  users = ios_users + android_users

  if users > 0
    android_percent = ((android_users * 100) / users)
    ios_percent = ((ios_users * 100) / users)
  else
    android_percent = ios_percent = 50

  chartUsers = new Chart($('#chartUsersContainer'), {
    type: 'doughnut',
    data : {
            labels: ['iOS', 'Android']
            datasets: [{
                        data: [ios_percent.toFixed(3), android_percent.toFixed(3)]
                        backgroundColor: ['#F08A42', '#C0D838']
                        borderWidth: 5
                      }],
          },
    options: {
                layout: { padding:{ top:'30', bottom: '30' } }
                title: { display: false }
                tooltips: {
                  callbacks: { label: (tooltipItem, data) -> return data.labels[tooltipItem.index] + ': ' + data.datasets[tooltipItem.datasetIndex].data[tooltipItem.index] + ' %' }
                }
                legend: {
                          position: 'right'
                          onClick: ()-> return false
                        }
              }
  })

  documents = parseInt($('#documents').val())
  mobile_documents = parseInt($('#mobile_documents').val())

  if documents > 0
    mobile_documents_percent = ((mobile_documents * 100) / documents)
  else
    mobile_documents_percent = 0

  chartDocuments = new Chart($('#chartDocumentsContainer'), {
    type: 'pie',
    data : {
            labels: ['Via iDocus', 'Via App Mobile']
            datasets: [{
                        data: [(100 - mobile_documents_percent).toFixed(3), mobile_documents_percent.toFixed(3)]
                        backgroundColor: ['#018CCF', '#FF420E']
                        borderWidth: 0
                      }],
          },
    options: {
                layout: { padding:{ top:'30', bottom: '30' } }
                title: { display: false }
                tooltips: {
                  callbacks: { label: (tooltipItem, data) -> return data.labels[tooltipItem.index] + ': ' + data.datasets[tooltipItem.datasetIndex].data[tooltipItem.index] + ' %' }
                }
                legend: {
                          position: 'right'
                          onClick: ()-> return false
                        }
              }
  })