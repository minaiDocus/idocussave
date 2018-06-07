window.onload = () ->
  ios_users = parseInt($('#ios_users').val())
  android_users = parseInt($('#android_users').val())
  users = ios_users + android_users

  max_step = android_users
  min_step = ios_users
  if (ios_users > android_users)
    max_step = ios_users
    min_step = android_users

  graduation_step = Math.ceil(min_step / 2)
  if (graduation_step <= 0)
    graduation_step = Math.ceil(max_step / 4)


  chartUsers = new Chart($('#chartUsersContainer'), {
    type: 'bar',
    data : {
            labels: ['iOS', 'Android']
            datasets: [{
                        data: [ios_users, android_users]
                        backgroundColor: ['#F08A42', '#C0D838']
                        borderColor : ['#FA7010', '#B0A000']
                        borderWidth: 2
                      }],
          },
    options: {
                layout: { padding:{ top:'10', bottom: '10' } }
                title: { display: true, text: 'Plateforme' }
                tooltips: {
                  callbacks: { label: (tooltipItem, data) -> return data.labels[tooltipItem.index] + ': ' + data.datasets[tooltipItem.datasetIndex].data[tooltipItem.index] + ' utilisateurs'}
                }
                legend: { display: false }
                scales: {
                  yAxes: [{
                            ticks: {
                                suggestedMin: 0,
                                suggestedMax: users,
                                stepSize: graduation_step
                            }
                          }]
                }
              }
  })

  mobile_users   = parseInt($('#mobile_users').val())
  users_uploader = parseInt($('#users_uploader').val())

  users_uploader_percent = 0
  if mobile_users > 0
    users_uploader_percent = ((users_uploader * 100) / mobile_users)

  chartUploaders = new Chart($('#chartUploaderContainer'), {
    type: 'doughnut',
    data : {
            labels: ['Consultation', 'Téléversement']
            datasets: [{
                        data: [(100 - users_uploader_percent).toFixed(3), users_uploader_percent.toFixed(3)]
                        backgroundColor: ['#018CCF', '#FF420E']
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


  documents        = parseInt($('#documents').val())
  mobile_documents = parseInt($('#mobile_documents').val())

  mobile_documents_percent = 0
  if documents > 0
    mobile_documents_percent = ((mobile_documents * 100) / documents)


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