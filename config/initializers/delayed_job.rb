Delayed::Worker.destroy_failed_jobs = false
Delayed::Worker.default_priority = 10
Delayed::Worker.max_run_time = 1.hour
Delayed::Worker.default_queue_name = 'main'
Delayed::Worker.delay_jobs = !Rails.env.test?
