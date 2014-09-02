Delayed::Worker.destroy_failed_jobs = false
Delayed::Worker.default_priority = 10
Delayed::Worker.max_run_time = 2.hours
Delayed::Worker.delay_jobs = !Rails.env.test?
